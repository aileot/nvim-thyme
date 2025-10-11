(import-macros {: when-not} :thyme.macros)

;; WARN: Do NOT use `require` modules which depend on config in .nvim-thyme.fnl
;; until `.nvim-thyme.fnl` is loaded.

(local {: debug? : config-filename : config-path} (require :thyme.const))

(local {: file-readable? : assert-is-fnl-file : read-file}
       (require :thyme.util.fs))

(when-not (file-readable? config-path)
  (require :thyme.config.fallback))

(local default-opts (require :thyme.config.defaults))

(local {: denied?} (require :thyme.util.trust))

(local RollbackManager (require :thyme.rollback.manager))
(local ConfigRollbackManager (RollbackManager.new :config ".fnl"))

;; NOTE: Please keep this security check simple.
(local nvim-appname vim.env.NVIM_APPNAME)
(local secure-nvim-env? (or (= nil nvim-appname) (= "" nvim-appname)))

(local cache {})

;; HACK: Make sure to use `require` to modules which depend on config in
;; .nvim-thyme.fnl after `.nvim-thyme.fnl` is loaded.

(fn notify-once! [msg ...]
  ;; NOTE: Avoid `Messenger:notify!`, which depends on this module
  ;; `thyme.config`; otherwise, stack overflow.
  ;; NOTE: The message format follows that of Messenger.
  (vim.notify_once (.. "thyme(config): " msg) ;
                   ...))

(fn read-config-with-backup! [config-file-path]
  "Return config table of `config-file-path`. With any errors in reading
current config, the config for the current nvim session will be rolled back to
the active backup, if available.
@param config-file string a directory path.
@return table"
  (assert-is-fnl-file config-file-path)
  ;; NOTE: fennel is likely to get into loop or previous error.
  (let [fennel (require :fennel)
        backup-name "default"
        backup-handler (ConfigRollbackManager:backup-handler-of backup-name)
        mounted-backup-path (backup-handler:determine-mounted-backup-path)
        ?config-code (if (file-readable? mounted-backup-path)
                         (let [msg (-> "rollback config to mounted backup (created at %s)"
                                       (: :format
                                          (backup-handler:determine-active-backup-birthtime)))]
                           (notify-once! msg vim.log.levels.WARN)
                           (read-file mounted-backup-path))
                         (do
                           (when (and secure-nvim-env?
                                      (denied? config-file-path))
                             (vim.secure.trust {:action "remove"
                                                :path config-file-path})
                             (notify-once! (: "Previously the attempt to load %s has been denied.
However, nvim-thyme asks you again to proceed just in case you accidentally denied your own config file."
                                              :format config-filename)))
                           ;; NOTE: The other choices than "allow" in
                           ;; `vim.secure.read` prompt  returns `nil`.
                           (vim.secure.read config-file-path)))
        compiler-options {:error-pinpoint ["|>>" "<<|"]
                          :filename config-file-path}
        _ (set cache.evaluating? true)
        (ok? ?result) (if ?config-code
                          (xpcall #(fennel.eval ?config-code compiler-options)
                                  fennel.traceback)
                          (do
                            (notify-once! "Failed to read config, fallback to the default options"
                                          vim.log.levels.WARN)
                            default-opts))
        _ (set cache.evaluating? false)]
    ;; NOTE: Make sure `evaluating?` is reset to avoid `require` loop.
    (if ok?
        (let [?config ?result]
          (when (and ?config-code
                     (backup-handler:should-update-backup? ?config-code))
            (backup-handler:write-backup! config-file-path)
            (backup-handler:cleanup-old-backups!))
          (or ?config {}))
        (let [backup-path (backup-handler:determine-active-backup-path)
              error-msg ?result
              msg (-> "failed to evaluating %s with the following error:\n%s"
                      (: :format config-filename error-msg))]
          (notify-once! msg vim.log.levels.ERROR)
          (if (file-readable? backup-path)
              (let [msg (-> "temporarily restore config from backup created at %s
HINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.
To stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."
                            (: :format
                               (backup-handler:determine-active-backup-birthtime)))]
                (notify-once! msg vim.log.levels.WARN)
                ;; Return the backup.
                (fennel.dofile backup-path compiler-options))
              (do
                (notify-once! "No backup found, fallback to the default options"
                              vim.log.levels.WARN)
                default-opts))))))

(set cache.main-config {})

(fn get-config []
  "Return the config found at stdpath('config') on the first load.
@return table Thyme config"
  (if (next cache.main-config)
      cache.main-config
      (let [user-config (read-config-with-backup! config-path)]
        (set cache.main-config
             (vim.tbl_deep_extend :force default-opts user-config))
        cache.main-config)))

(fn config-file? [path]
  "Tell if `path` is a thyme's config file.
@param path string
@return boolean"
  ;; NOTE: Just in case, do not compare in full path.
  (= config-filename (vim.fs.basename path)))

(setmetatable {: config-file?
               ;; Make sure `get-config` readonly. It is only intended to be
               ;; called for checkhealth.
               :get-config #(let [config (vim.deepcopy (get-config))]
                              ;; NOTE: The options .source, .module-name, and
                              ;; .filename only represents the last used
                              ;; options for the last evaluated fennel codes.
                              (set config.compiler-options.source nil)
                              (set config.compiler-options.module-name nil)
                              (set config.compiler-options.filename nil)
                              (when config.command.compiler-options
                                (set config.command.compiler-options.source nil)
                                (set config.command.compiler-options.module-name
                                     nil)
                                (set config.command.compiler-options.filename
                                     nil))
                              config)}
  {:__index (fn [_self k]
              (case k
                "?error-msg" (when cache.evaluating?
                               ;; NOTE: This message is intended to be used by
                               ;; searcher as the reason why the searcher does
                               ;; not return a chunk.
                               (.. "recursion detected in evaluating "
                                   config-filename))
                _ (let [config (get-config)]
                    ;; NOTE: Do NOT overwrite self with `rawset` to keep
                    ;; __newindex working.
                    (case (. default-opts k)
                      nil (error (.. "unexpected option detected: " k))
                      _ (. config k)))))
   :__newindex (when-not debug?
                 (fn [_ key]
                   (error (.. "thyme.config is readonly; accessing " key))))})
