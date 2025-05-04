(local {: debug? : config-filename : config-path} (require :thyme.const))
(local {: file-readable? : assert-is-fnl-file : read-file : write-fnl-file!}
       (require :thyme.utils.fs))

(local RollbackManager (require :thyme.rollback))
(local ConfigRollbackManager (RollbackManager.new :config ".fnl"))

;; NOTE: Please keep this security check simple.
(local nvim-appname vim.env.NVIM_APPNAME)
(local secure-nvim-env? (or (= nil nvim-appname) (= "" nvim-appname)))

(local default-opts ;
       {:max-rollbacks 10
        ;; TODO: Inplement :preproc and set the default value to `#$`.
        :preproc nil
        :compiler-options {}
        :fnl-dir "fnl"
        ;; Set to fennel.macro-path for macro modules.
        :macro-path (-> ["./fnl/?.fnlm"
                         "./fnl/?/init.fnlm"
                         "./fnl/?.fnl"
                         "./fnl/?/init-macros.fnl"
                         "./fnl/?/init.fnl"]
                        (table.concat ";"))
        :command {:compiler-options nil
                  :fnl-cmd-prefix "Fnl"
                  :cmd-history {:method "overwrite" :trailing-parens "omit"}}
        :watch {:event [:BufWritePost :FileChangedShellPost]
                :pattern "*.fnlm?"
                :notifier vim.notify
                :strategy "recompile"}})

(local cache {})

(set cache.main-config
     (setmetatable {}
       {:__index (fn [self k]
                   (if (= k "?error-msg")
                       ;; As a placeholder.
                       nil
                       (case (rawget default-opts k)
                         val (do
                               (rawset self k val)
                               val)
                         _ (error (.. "unexpected option detected: "
                                      (vim.inspect k))))))
        :__newindex (if debug?
                        (fn [self k v]
                          (rawset self k v))
                        (fn [self k v]
                          (if (= nil (rawget default-opts k))
                              (error (.. "unexpected option detected: "
                                         (vim.inspect k)))
                              (rawset self k v))))}))

(when (not (file-readable? config-path))
  ;; Generate main-config-file if missing.
  (case (vim.fn.confirm (: "Missing \"%s\" at %s. Generate and open it?"
                           :format config-filename (vim.fn.stdpath :config))
                        "&No\n&yes" 1 :Warning)
    2 (let [this-dir (-> (debug.getinfo 1 "S")
                         (. :source)
                         (: :sub 2)
                         (vim.fs.dirname))
            example-config-filename (.. config-filename ".example")
            [example-config-path] (vim.fs.find example-config-filename
                                               {:upward true
                                                :type "file"
                                                :path this-dir})
            recommended-config (read-file example-config-path)]
        (write-fnl-file! config-path recommended-config)
        (vim.cmd.tabedit config-path)
        (-> #(when (= config-path (vim.api.nvim_buf_get_name 0))
               (case (vim.fn.confirm "Trust this file? Otherwise, it will ask your trust again on nvim restart"
                                     "&Yes\n&no" 1 :Question)
                 2 (error (.. "abort trusting " config-path))
                 _ (vim.cmd.trust)))
            (vim.defer_fn 800)))
    _ (error "abort proceeding with nvim-thyme")))

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
        backup-handler (ConfigRollbackManager:backupHandlerOf backup-name)
        mounted-backup-path (backup-handler:determine-mounted-backup-path)
        config-code (if (file-readable? mounted-backup-path)
                        (let [msg (-> "[thyme] rollback config to mounted backup (created at %s)"
                                      (: :format
                                         (backup-handler:determine-active-backup-birthtime)))]
                          (vim.notify_once msg vim.log.levels.WARN)
                          (read-file mounted-backup-path))
                        secure-nvim-env?
                        (read-file config-file-path)
                        (vim.secure.read config-file-path))
        compiler-options {:error-pinpoint ["|>>" "<<|"]
                          :filename config-file-path}
        _ (set cache.evaluating? true)
        (ok? ?result) (pcall fennel.eval config-code compiler-options)
        _ (set cache.evaluating? false)]
    ;; NOTE: Make sure `evalutating?` is reset to avoid `require` loop.
    (if ok?
        (let [?config ?result]
          (when (backup-handler:should-update-backup? config-code)
            (backup-handler:write-backup! config-file-path)
            (backup-handler:cleanup-old-backups!))
          (or ?config {}))
        (let [backup-path (backup-handler:determine-active-backup-path)
              error-msg ?result
              msg (-> "[thyme] failed to evaluating %s with the following error:\n%s"
                      (: :format config-filename error-msg))]
          (vim.notify_once msg vim.log.levels.ERROR)
          (if (file-readable? backup-path)
              (let [msg (-> "[thyme] temporarily restore config from backup created at %s
HINT: You can reduce its annoying errors during repairing the module running `:ThymeRollbackMount` to keep the active backup in the next nvim session.
To stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."
                            (: :format
                               (backup-handler:determine-active-backup-birthtime)))]
                (vim.notify_once msg vim.log.levels.WARN)
                ;; Return the backup.
                (fennel.dofile backup-path compiler-options))
              {})))))

(fn get-config []
  "Return the config found at stdpath('config') on the first load.
@return table Thyme config"
  (if cache.evaluating?
      ;; NOTE: This expects `(pcall require missing-mdodule)` in .nvim-thyme.fnl.
      {:?error-msg (.. "recursion detected in evaluating " config-filename)}
      (next cache.main-config)
      cache.main-config
      (let [user-config (read-config-with-backup! config-path)
            mt (getmetatable cache.main-config)]
        (set cache.main-config
             (vim.tbl_deep_extend :force default-opts user-config))
        (setmetatable cache.main-config mt)
        cache.main-config)))

(fn config-file? [path]
  "Tell if `path` is a thyme's config file.
@param path string
@return boolean"
  ;; NOTE: Just in case, do not compare in full path.
  (= config-filename (vim.fs.basename path)))

(setmetatable {: get-config : config-file?}
  {:__index (fn [_self k]
              (case k
                "?error-msg" (when cache.evaluating?
                               (.. "recursion detected in evaluating "
                                   config-filename))
                _ (let [config (get-config)]
                    (case (. config k)
                      val (do
                            ;; FIXME: Handle nested table values? Tests fails
                            ;; because `max-rollbacks` is ignored.
                            ;; (rawset _self k val)
                            val)
                      _ (error (.. "unexpected option detected: " k))))))
   :__newindex (fn [self k v]
                 (error k)
                 (let [config (get-config)]
                   (tset config k v)
                   (case (. config k)
                     val (rawset self k val))))})
