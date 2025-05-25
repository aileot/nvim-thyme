(import-macros {: when-not : last : nvim-get-option} :thyme.macros)

(local {: debug?} (require :thyme.const))

(local {: file-readable? : write-lua-file!} (require :thyme.util.fs))

(local {: gsplit} (require :thyme.util.iterator))
(local {: can-restore-file? : restore-file!} (require :thyme.util.pool))

(local Messenger (require :thyme.util.class.messenger))
(local LoaderMessenger (Messenger.new "loader/runtime"))
(local RollbackLoaderMessenger (Messenger.new "loader/runtime/rollback"))

(local {: get-runtime-files} (require :thyme.wrapper.nvim))

;; WARN: Do NOT load thyme.config in this module-wise; otherwise into loop.
;; (local Config (require :thyme.config))

(local Observer (require :thyme.dependency.observer))

(local {: locate-fennel-path! : load-fennel}
       (require :thyme.loader.fennel-module))

(local {: initialize-macro-searcher-on-rtp!}
       (require :thyme.loader.macro-module))

(local RollbackManager (require :thyme.rollback.manager))
(local RuntimeModuleRollbackManager (RollbackManager.new :runtime ".lua"))

;; NOTE: To initialize fennel.path and fennel.macro-path, cache.rtp must not
;; start with vim.o.rtp.
(local cache {:rtp nil})

(fn initialize-module-searcher-on-rtp! [fennel]
  (let [std-config-home (vim.fn.stdpath :config)
        Config (require :thyme.config)
        fnl-dir (-> (.. "/" Config.fnl-dir "/")
                    (string.gsub "//+" "/"))
        fennel-path (-> (icollect [_ suffix (ipairs [:?.fnl :?/init.fnl])]
                          (.. std-config-home fnl-dir suffix))
                        (table.concat ";"))]
    ;; NOTE: Overwriting fennel.{path,macro-path} considering &rtp is at least
    ;; necessary to make `include` work on &rtp. It will also affect the
    ;; behaviors of other Fennel functions, for better or worse.
    (set fennel.path fennel-path)))

(fn update-fennel-paths! [fennel]
  (let [Config (require :thyme.config)
        base-path-cache (setmetatable {}
                          {:__index (fn [self key]
                                      (rawset self key
                                              (get-runtime-files [key] true))
                                      (. self key))})
        macro-path (-> (icollect [fnl-template (gsplit Config.macro-path ";")]
                         (if (= "/" (fnl-template:sub 1 1))
                             fnl-template
                             (let [(offset rest) (fnl-template:match "^%./([^?]*)(.-)$")
                                   base-paths (. base-path-cache offset)]
                               (-> (icollect [_ dir (pairs base-paths)]
                                     (.. dir rest))
                                   (table.concat ";")))))
                       (table.concat ";")
                       (: :gsub "/%./" "/"))]
    (set fennel.macro-path macro-path)))

(fn write-lua-file-with-backup! [lua-path lua-code module-name]
  "Write `lua-path` with `lua-code` creating backup.
@param lua-path string
@param lua-code string
@param module-name string
@return undefined"
  (write-lua-file! lua-path lua-code)
  (let [backup-handler (RuntimeModuleRollbackManager:backup-handler-of module-name)]
    (when (backup-handler:should-update-backup? lua-code)
      (backup-handler:write-backup! lua-path))))

(fn module-name->fnl-file-on-rtp! [module-name]
  "Search for `fnl-file` from `module-name` on `&rtp`.
@param module-name string
@return string|false fnl path, or `false`
@return string? error message only with `false` in the first return value."
  (let [fennel (require :fennel)]
    (when (or (= nil cache.rtp) debug?)
      (initialize-macro-searcher-on-rtp! fennel)
      (initialize-module-searcher-on-rtp! fennel))
    (when-not (= cache.rtp vim.o.rtp)
      (set cache.rtp vim.o.rtp)
      (update-fennel-paths! fennel))
    (fennel.search-module module-name fennel.path)))

(fn search-fnl-module-on-rtp! [module-name ...]
  "Search for fennel source file to compile into lua and save in nvim-thyme
cache dir.
@param module-name string
@return string|function a lua chunk in function, or a string to tell why failed to load module."
  (if (module-name:find "^vim%.")
      ;; NOTE: This `vim` module detection is a workaround for not to be
      ;; a suspect of the errors missing such `vim` modules due to a build
      ;; failure in neovim development; otherwise, get into infinite loop.
      (let [path (-> vim.env.VIMRUNTIME
                     (vim.fs.joinpath "lua"))]
        (loadfile path))
      (= :fennel module-name)
      ;; NOTE: The searchers must not be initialized here because this
      ;; searcher only receives "fennel" when the cache is cleared.
      (let [fennel-lua-path (locate-fennel-path!)]
        (load-fennel fennel-lua-path))
      ;; NOTE: `thyme.compiler` depends on the module `fennel` so that
      ;; must be loaded here; otherwise, get into infinite loop.
      (let [Config (require :thyme.config)]
        (if Config.?error-msg ;
            (LoaderMessenger:mk-failure-reason Config.?error-msg)
            (let [backup-handler (RuntimeModuleRollbackManager:backup-handler-of module-name)
                  file-loader (fn [path ...]
                                ;; Explicitly discard the rest params, or tests
                                ;; could fail.
                                (loadfile path))]
              (or (case (case (RuntimeModuleRollbackManager:inject-mounted-backup-searcher! package.loaders
                                                                                            file-loader)
                          searcher (searcher module-name))
                    msg|chunk (case (type msg|chunk)
                                ;; NOTE: Discard unwothy msg in the edge
                                ;; cases on initializations.
                                :function
                                (values msg|chunk)))
                  (case (case (module-name->fnl-file-on-rtp! module-name)
                          fnl-path (let [fennel (require :fennel)
                                         {: determine-lua-path} (require :thyme.compiler.cache)
                                         lua-path (determine-lua-path module-name)
                                         compiler-options Config.compiler-options]
                                     (case (Observer:observe! fennel.compile-string
                                                              fnl-path lua-path
                                                              compiler-options
                                                              module-name)
                                       (true lua-code) (do
                                                         (if (can-restore-file? lua-path
                                                                                lua-code)
                                                             (restore-file! lua-path)
                                                             (do
                                                               (write-lua-file-with-backup! lua-path
                                                                                            lua-code
                                                                                            module-name)
                                                               (backup-handler:cleanup-old-backups!)))
                                                         (load lua-code
                                                               lua-path))
                                       (_ raw-msg)
                                       (let [raw-msg-body (-> "%s is found for the runtime/%s, but failed to compile it"
                                                              (: :format
                                                                 fnl-path
                                                                 module-name))
                                             msg (-> "%s\n\t%s"
                                                     (: :format raw-msg-body
                                                        raw-msg)
                                                     (LoaderMessenger:mk-failure-reason))]
                                         (values nil msg))))
                          (_ raw-msg) (values nil raw-msg))
                    chunk (values chunk)
                    (_ error-msg)
                    (let [backup-path (backup-handler:determine-active-backup-path module-name)
                          max-rollbacks Config.max-rollbacks
                          rollback-enabled? (< 0 max-rollbacks)]
                      (if (and rollback-enabled? (file-readable? backup-path))
                          (let [msg (: "temporarily restore backup for the module/%s (created at %s) due to the following error:
%s

HINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.
To stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."
                                       :format module-name
                                       (backup-handler:determine-active-backup-birthtime module-name)
                                       error-msg)]
                            (RollbackLoaderMessenger:notify-once! msg
                                                                  vim.log.levels.WARN)
                            (loadfile backup-path))
                          (LoaderMessenger:mk-failure-reason error-msg))))))))))

{: search-fnl-module-on-rtp!
 : write-lua-file-with-backup!
 : RuntimeModuleRollbackManager}
