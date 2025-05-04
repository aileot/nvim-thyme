(import-macros {: when-not : last : nvim-get-option} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: debug? : lua-cache-prefix} (require :thyme.const))

(local {: file-readable?
        : assert-is-file-readable
        : read-file
        : write-lua-file!
        &as fs} (require :thyme.utils.fs))

(local {: gsplit} (require :thyme.utils.iterator))
(local {: can-restore-file? : restore-file!} (require :thyme.utils.pool))

(local {: get-runtime-files} (require :thyme.wrapper.nvim))

(local Config (require :thyme.config))

(local {: pcall-with-logger!} (require :thyme.module-map.callstack))

(local {: initialize-macro-searcher-on-rtp!} (require :thyme.searcher.macro))

(local RollbackManager (require :thyme.rollback))
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
        fennel-lua-path (Path.join fennel-src-root fennel-lua-file)
        ;; NOTE: As long as the args of vim.fn.system is a list instead of a
        ;; string the process is independent from vim.o.shell. The
        ;; independence from shell also means that shell specific keywords
        ;; like `|`, `&&`, etc., would be interpreted as `make` arg.
        ;; TODO: Apply appropriate filename escapes.
        output (vim.fn.system [:make :-C fennel-src-root fennel-lua-file])]
    (when-not (= 0 vim.v.shell_error)
      (error (.. "failed to compile fennel.lua with exit code: "
                 vim.v.shell_error "\ndump:\n" output)))
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
  (let [base-path-cache (setmetatable {}
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
  (let [backup-handler (ModuleRollbackManager:backupHandlerOf module-name)]
    (when (backup-handler:should-update-backup? lua-code)
      (backup-handler:write-backup! lua-path))))

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
      (let [fennel (require :fennel)]
        (or Config.?error-msg
            (let [backup-handler (ModuleRollbackManager:backupHandlerOf module-name)]
              (ModuleRollbackManager:inject-mounted-backup-searcher! package.loaders)
              (when (or (= nil cache.rtp) debug?)
                (initialize-macro-searcher-on-rtp! fennel)
                (initialize-module-searcher-on-rtp! fennel))
              (when-not (= cache.rtp vim.o.rtp)
                (set cache.rtp vim.o.rtp)
                (update-fennel-paths! fennel))
              (case (case (fennel.search-module module-name fennel.path)
                      fnl-path (let [{: determine-lua-path} (require :thyme.compiler.cache)
                                     lua-path (determine-lua-path module-name)
                                     compiler-options Config.compiler-options]
                                 (case (pcall-with-logger! fennel.compile-string
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
                                                           (backup-handler:cleanup-old-backups! module-name)))
                                                     (load lua-code lua-path))
                                   (_ msg) (let [msg-prefix (: "
    thyme-loader: %s is found for the module %s, but failed to compile it
    \t" :format
                                                               fnl-path
                                                               module-name)]
                                             (values nil (.. msg-prefix msg)))))
                      (_ msg) (values nil (.. "\nthyme-loader: " msg)))
                chunk chunk
                (_ error-msg)
                (let [backup-path (backup-handler:determine-active-backup-path module-name)
                      max-rollbacks Config.max-rollbacks
                      rollback-enabled? (< 0 max-rollbacks)]
                  (if (and rollback-enabled? (file-readable? backup-path))
                      (let [msg (: "thyme-rollback-loader: temporarily restore backup for the module %s (created at %s) due to the following error: %s
HINT: You can reduce its annoying errors during repairing the module running `:ThymeRollbackMount` to keep the active backup in the next nvim session.
To stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."
                                   :format module-name
                                   (backup-handler:determine-active-backup-birthtime module-name)
                                   error-msg)]
                        (vim.notify_once msg vim.log.levels.WARN)
                        (loadfile backup-path))
                      error-msg))))))))

{: search-fnl-module-on-rtp! : write-lua-file-with-backup!}
