(import-macros {: when-not : last : nvim-get-option} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: lua-cache-prefix} (require :thyme.const))

(local {: file-readable?
        : assert-is-file-readable
        : read-file
        : write-lua-file!
        &as fs} (require :thyme.utils.fs))

(local {: gsplit} (require :thyme.utils.iterator))
(local {: can-restore-file? : restore-file!} (require :thyme.utils.pool))

(local {: get-runtime-files} (require :thyme.wrapper.nvim))

(local {: get-config} (require :thyme.config))

(local {: pcall-with-logger!} (require :thyme.module-map.callstack))

(local {: initialize-macro-searcher-on-rtp!} (require :thyme.searcher.macro))

(local BackupManager (require :thyme.utils.backup-manager))
(local ModuleBackupManager (BackupManager.new :module-rollback))

;; Note: To initialize fennel.path and fennel.macro-path, cache.rtp must not
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
        ;; Note: As long as the args of vim.fn.system is a list instead of a
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
    ;; Note: It must return Lua expression, i.e., read-file is unsuitable.
    ;; Note: Evaluating fennel.lua by (require :fennel) is unsuitable;
    ;; otherwise, it gets into infinite loop since this function runs as
    ;; a loader of `require`.
    (assert (loadfile cached-fennel-path))))

(fn initialize-module-searcher-on-rtp! [fennel]
  (let [std-config-home (vim.fn.stdpath :config)
        config (get-config)
        fnl-dir (-> (.. "/" config.fnl-dir "/")
                    (string.gsub "//+" "/"))
        fennel-path (-> (icollect [_ suffix (ipairs [:?.fnl :?/init.fnl])]
                          (.. std-config-home fnl-dir suffix))
                        (table.concat ";"))]
    ;; Note: Overwriting fennel.{path,macro-path} considering &rtp is at least
    ;; necessary to make `include` work on &rtp. It will also affect the
    ;; behaviors of other Fennel functions, for better or worse.
    (set fennel.path fennel-path)))

(fn update-fennel-paths! [fennel]
  (let [config (get-config)
        base-path-cache (setmetatable {}
                          {:__index (fn [self key]
                                      (rawset self key
                                              (get-runtime-files [key] true))
                                      (. self key))})
        macro-path (-> (icollect [fnl-template (gsplit config.macro-path ";")]
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
  (write-lua-file! lua-path lua-code)
  (when (ModuleBackupManager:should-update-backup! module-name lua-code)
    (ModuleBackupManager:create-module-backup! module-name lua-path)))

(fn search-fnl-module-on-rtp! [module-name ...]
  "Search for fennel source file to compile into lua and save in nvim-thyme
cache dir.
@param module-name string
@return string|function a lua chunk in function, or a string to tell why failed to load module."
  (if (= :fennel module-name)
      ;; Note: The searchers must not be initialized here because this
      ;; searcher only receives "fennel" when the cache is cleared.
      (compile-fennel-into-rtp!)
      ;; Note: `thyme.compiler` depends on the module `fennel` so that
      ;; must be loaded here; otherwise, get into infinite loop.
      (let [fennel (require :fennel)
            {: get-config} (require :thyme.config)
            config (get-config)]
        (when (= nil cache.rtp)
          (initialize-macro-searcher-on-rtp! fennel)
          (initialize-module-searcher-on-rtp! fennel))
        (when-not (= cache.rtp vim.o.rtp)
          (set cache.rtp vim.o.rtp)
          (update-fennel-paths! fennel))
        (case (case (fennel.search-module module-name fennel.path)
                fnl-path (let [{: module-name->lua-path} (require :thyme.compiler.cache)
                               lua-path (module-name->lua-path module-name)
                               compiler-options config.compiler-options]
                           (case (pcall-with-logger! fennel.compile-string
                                                     fnl-path lua-path
                                                     compiler-options
                                                     module-name)
                             (true lua-code) (do
                                               (if (can-restore-file? lua-path
                                                                      lua-code)
                                                   (restore-file! lua-path)
                                                   (write-lua-file-with-backup! lua-path
                                                                                lua-code
                                                                                module-name))
                                               (load lua-code lua-path))
                             (_ msg) (let [msg-prefix (: "
thyme-loader: %s is found for the module %s, but failed to compile it
\t" :format fnl-path
                                                         module-name)]
                                       (values nil (.. msg-prefix msg)))))
                (_ msg) (values nil (.. "\nthyme-loader: " msg)))
          chunk chunk
          (_ error-msg)
          (let [backup-path (ModuleBackupManager:module-name->backup-path module-name)
                rollback? config.rollback]
            (if (and rollback? (file-readable? backup-path))
                (let [msg (: "thyme-rollback-loader: temporarily restore backup for the module %s due to the following error: %s"
                             :format module-name error-msg)]
                  (vim.notify_once msg vim.log.levels.WARN)
                  (loadfile backup-path))
                error-msg))))))

{: search-fnl-module-on-rtp! : write-lua-file-with-backup!}
