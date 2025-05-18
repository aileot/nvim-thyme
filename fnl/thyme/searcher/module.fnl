(import-macros {: when-not : last : nvim-get-option} :thyme.macros)

(local {: debug? : lua-cache-prefix} (require :thyme.const))

(local Path (require :thyme.utils.path))

(local {: executable?
        : file-readable?
        : assert-is-file-readable
        : read-file
        : write-lua-file!
        &as fs} (require :thyme.utils.fs))

(local {: gsplit} (require :thyme.utils.iterator))
(local {: can-restore-file? : restore-file!} (require :thyme.utils.pool))

(local Messenger (require :thyme.utils.messenger))
(local LoaderMessenger (Messenger.new "loader"))
(local RollbackLoaderMessenger (Messenger.new "loader/rollback"))

(local {: get-runtime-files} (require :thyme.wrapper.nvim))

;; WARN: Do NOT load thyme.config in this module-wise; otherwise into loop.
;; (local Config (require :thyme.config))

(local Observer (require :thyme.dependency.observer))

(local {: initialize-macro-searcher-on-rtp!} (require :thyme.searcher.macro))

(local RollbackManager (require :thyme.rollback.manager))
(local ModuleRollbackManager (RollbackManager.new :module ".lua"))

;; NOTE: To initialize fennel.path and fennel.macro-path, cache.rtp must not
;; start with vim.o.rtp.
(local cache {:rtp nil})

(fn compile-fennel-into-rtp! []
  "Compile src/fennel.fnl into lua/ at nvim-thyme cache dir, and return the
fennel.lua.
@return function a lua chunk of fennel.lua."
  (let [rtp (nvim-get-option :rtp)
        fnl-src-path (or (rtp:match (Path.join "([^,]+" "fennel),"))
                         (rtp:match (Path.join "([^,]+" "fennel)$"))
                         (error "please make sure to add the path to fennel repo in `&runtimepath`"))
        fennel-lua-file :fennel.lua
        cached-fennel-path (Path.join lua-cache-prefix fennel-lua-file)
        [fennel-src-Makefile] (vim.fs.find :Makefile
                                           {:upward true :path fnl-src-path})
        _ (assert fennel-src-Makefile "Could not find Makefile for fennel.lua.")
        fennel-src-root (vim.fs.dirname fennel-src-Makefile)
        fennel-lua-path (Path.join fennel-src-root fennel-lua-file)]
    (let [on-exit (fn [out]
                    (assert (= 0 (tonumber out.code))
                            (-> "failed to compile fennel.lua with code: %s\n%s"
                                (: :format out.code out.stderr))))
          LUA (when-not (executable? "lua")
                (or vim.env.LUA "nvim --clean --headless -l"))
          env {: LUA}
          make-cmd [:make :-C fennel-src-root fennel-lua-file]]
      (-> (vim.system make-cmd {:text true : env} on-exit)
          (: :wait)))
    (-> (vim.fs.dirname cached-fennel-path)
        (vim.fn.mkdir :p))
    (if (can-restore-file? cached-fennel-path (read-file fennel-lua-path))
        (restore-file! cached-fennel-path)
        (fs.copyfile fennel-lua-path cached-fennel-path))
    (assert-is-file-readable fennel-lua-path)
    (assert-is-file-readable cached-fennel-path)
    ;; NOTE: It must return Lua expression, i.e., read-file is unsuitable.
    ;; NOTE: Evaluating fennel.lua by (require :fennel) is unsuitable;
    ;; otherwise, it gets into infinite loop since this function runs as
    ;; a loader of `require`.
    (assert (loadfile cached-fennel-path))))

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
  (let [backup-handler (ModuleRollbackManager:backup-handler-of module-name)]
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
  (if (= :fennel module-name)
      ;; NOTE: The searchers must not be initialized here because this
      ;; searcher only receives "fennel" when the cache is cleared.
      (compile-fennel-into-rtp!)
      ;; NOTE: `thyme.compiler` depends on the module `fennel` so that
      ;; must be loaded here; otherwise, get into infinite loop.
      (let [Config (require :thyme.config)]
        (or Config.?error-msg ;
            (let [backup-handler (ModuleRollbackManager:backup-handler-of module-name)
                  ?chunk (case (case (let [file-loader (fn [path ...]
                                                         ;; Explicitly discard
                                                         ;; the rest params, or
                                                         ;; tests could fail.
                                                         (loadfile path))]
                                       (ModuleRollbackManager:inject-mounted-backup-searcher! package.loaders
                                                                                              file-loader))
                                 searcher (searcher module-name))
                           msg|chunk (case (type msg|chunk)
                                       ;; NOTE: Discard unwothy msg in the edge
                                       ;; cases on initializations.
                                       :function
                                       msg|chunk))]
              (or ?chunk ;
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
                                       (let [raw-msg-body (-> "%s is found for the module/%s, but failed to compile it"
                                                              (: :format
                                                                 fnl-path
                                                                 module-name))
                                             msg-body (LoaderMessenger:wrap-msg raw-msg-body)
                                             msg (-> "
%s
\t%s"
                                                     (: :format msg-body
                                                        raw-msg))]
                                         (values nil msg))))
                          (_ raw-msg) (let [msg (LoaderMessenger:wrap-msg raw-msg)]
                                        (values nil (.. "\n" msg))))
                    chunk chunk
                    (_ error-msg)
                    (let [backup-path (backup-handler:determine-active-backup-path module-name)
                          max-rollbacks Config.max-rollbacks
                          rollback-enabled? (< 0 max-rollbacks)]
                      (if (and rollback-enabled? (file-readable? backup-path))
                          (let [msg (: "temporarily restore backup for the module/%s (created at %s) due to the following error: %s
HINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.
To stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."
                                       :format module-name
                                       (backup-handler:determine-active-backup-birthtime module-name)
                                       error-msg)]
                            (RollbackLoaderMessenger:notify-once! msg
                                                                  vim.log.levels.WARN)
                            (loadfile backup-path))
                          error-msg)))))))))

{: search-fnl-module-on-rtp! : write-lua-file-with-backup!}
