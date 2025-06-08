(import-macros {: when-not} :thyme.macros)

;; WARN: Do NOT use `require` modules which depend on config in .nvim-thyme.fnl
;; until `.nvim-thyme.fnl` is loaded.

(local {: debug? : config-filename : config-path : example-config-path}
       (require :thyme.const))

(local {: file-readable? : assert-is-fnl-file : read-file : write-fnl-file!}
       (require :thyme.util.fs))

;; NOTE: Please keep this security check simple.
(local nvim-appname vim.env.NVIM_APPNAME)
(local secure-nvim-env? (or (= nil nvim-appname) (= "" nvim-appname)))

(local std-config (vim.fn.stdpath :config))
(local std-fnl-dir? (vim.uv.fs_stat (vim.fs.joinpath std-config "fnl")))
(local use-lua-dir? (not std-fnl-dir?))

(local default-opts ;
       {:max-rollbacks 5
        :compiler-options {}
        :fnl-dir (if use-lua-dir? "lua" "fnl")
        ;; Set to fennel.macro-path for macro modules.
        :macro-path (-> ["./fnl/?.fnlm"
                         "./fnl/?/init.fnlm"
                         "./fnl/?.fnl"
                         "./fnl/?/init-macros.fnl"
                         "./fnl/?/init.fnl"
                         ;; NOTE: Only the last items can be `nil`s without errors.
                         (when use-lua-dir? (.. std-config "/lua/?.fnlm"))
                         (when use-lua-dir? (.. std-config "/lua/?/init.fnlm"))
                         (when use-lua-dir? (.. std-config "/lua/?.fnl"))
                         (when use-lua-dir?
                           (.. std-config "/lua/?/init-macros.fnl"))
                         (when use-lua-dir? (.. std-config "/lua/?/init.fnl"))]
                        (table.concat ";"))
        ;; (experimental)
        ;; What args should be passed to the callback?
        :preproc #$
        :notifier vim.notify
        ;; Since the highlighting output rendering are unstable on the
        ;; experimental vim._extui feature on the nvim v0.12.0 nightly, you can
        ;; disable treesitter highlights and make nvim-thyme return plain text
        ;; outputs instead on the keymap and command features.
        :disable-treesitter-highlights false
        :command {:compiler-options false
                  :cmd-history {:method "overwrite" :trailing-parens "omit"}
                  :Fnl {;; (experimental)
                        :default-range 0}
                  :FnlCompile {;; (experimental)
                               :default-range 0}}
        :keymap {:compiler-options false :mappings {}}
        :watch {:event [:BufWritePost :FileChangedShellPost]
                :pattern "*.{fnl,fnlm}"
                ;; TODO: Add :strategy recommended value to
                ;; .nvim-thyme.fnl.example.
                :strategy "clear-all"
                :macro-strategy "clear-all"}
        ;; (experimental)
        ;; TODO: Set the default keys once stable a bit.
        :dropin {:cmdline-key false
                 :cmdline-completion-key false
                 :cmdwin {:enter-key false}}})

(local cache {})

(when (not (file-readable? config-path))
  ;; Generate main-config-file if missing.
  (case (vim.fn.confirm (: "Missing \"%s\" at %s. Generate and open it?"
                           :format config-filename (vim.fn.stdpath :config))
                        "&No\n&yes" 1 :Warning)
    2 (let [recommended-config (read-file example-config-path)]
        (write-fnl-file! config-path recommended-config)
        (vim.cmd (.. "tabedit " config-path))
        (vim.wait 1000 #(= config-path (vim.api.nvim_buf_get_name 0)))
        (vim.cmd "redraw!")
        (when (= config-path (vim.api.nvim_buf_get_name 0))
          (case (vim.fn.confirm "Trust this file? Otherwise, it will ask your trust again on nvim restart"
                                "&Yes\n&no" 1 :Question)
            2 (let [buf-name (vim.api.nvim_buf_get_name 0)]
                (assert (= config-path buf-name)
                        (-> "expected %s, got %s"
                            (: :format config-path buf-name)))
                ;; NOTE: vim.secure.trust specifying path in its arg cannot
                ;; set "allow" to the "action" value.
                ;; NOTE: `:trust` to "allow" cannot take any path as the arg.
                (vim.cmd :trust))
            _ (do
                (vim.secure.trust {:action "remove" :path config-path})
                (case (vim.fn.confirm (-> "Aborted trusting %s. Exit?"
                                          (: :format config-path))
                                      "&No\n&yes" 1 :WarningMsg)
                  2 (os.exit 1))))))
    _ (case (vim.fn.confirm "Aborted proceeding with nvim-thyme. Exit?"
                            "&No\n&yes" 1 :WarningMsg)
        2 (os.exit 1))))

;; HACK: Make sure to use `require` to modules which depend on config in
;; .nvim-thyme.fnl after `.nvim-thyme.fnl` is loaded.

(local {: denied?} (require :thyme.util.trust))

(local RollbackManager (require :thyme.rollback.manager))
(local ConfigRollbackManager (RollbackManager.new :config ".fnl"))

(fn notify-once! [msg ...]
  ;; NOTE: Avoid `Messenger:notyfy!`, which depends on this module
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
               ;; Make sure `get-config` readonly. It is only intedended to be
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
