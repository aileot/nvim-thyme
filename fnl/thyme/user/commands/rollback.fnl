(import-macros {: command!} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: file-readable?} (require :thyme.utils.fs))
(local {: hide-file!} (require :thyme.utils.pool))
(local {: determine-lua-path} (require :thyme.compiler.cache))
(local RollbackManager (require :thyme.rollback))

(local M {})

(local RollbackCommandBackend {})

(λ RollbackCommandBackend.attach [kind]
  "Create a RollbackManager instance only to attach to the data stored for
`kind`.
@return RollbackManager"
  (let [ext-tmp ".tmp"]
    (RollbackManager.new kind ext-tmp)))

(fn RollbackCommandBackend.mount-backup! [kind modname]
  "Mount currently active backup for `modname` of the `kind`.
@param kind string
@param modname string an empty string indicates all the backups in the `kind`
@return boolean true if successfully mounted; false otherwise"
  (let [ext-tmp ".tmp"
        backup-handler (-> (RollbackCommandBackend.attach kind ext-tmp)
                           (: :backupHandlerOf modname))
        ok? (backup-handler:mount-backup!)]
    (when (and ok? (= kind :module))
      ;; Hide the corresponding lua cache from &rtp to make sure the
      ;; `mounted-rollback-loader` to be injected in `package.loaders` first.
      (case (determine-lua-path modname)
        lua-path (when (file-readable? lua-path)
                   (hide-file! lua-path))))
    ok?))

(fn RollbackCommandBackend.unmount-backup! [kind modname]
  "Unmount previously mounted backup for `backup-dir`.
@param backup-dir string
@return boolean true if module has been successfully unmounted, false otherwise."
  (let [ext-tmp ".tmp"
        backup-handler (-> (RollbackCommandBackend.attach kind ext-tmp)
                           (: :backupHandlerOf modname))]
    ;; NOTE: Do NOT mess up lines on unmounting, but leave the `restore-file!`
    ;; tasks to the searchers at runtime instead.
    (backup-handler:unmount-backup!)))

(fn RollbackCommandBackend.cmdargs->kind-modname [cmdargs]
  "Parse cmdargs (slash-separated) into two strings: `kind` and `modname`.
@param cmdargs string
@return kind string
@return modname string an empty string will indicates all the stored modulesof the `kind`."
  (cmdargs:match "([^/]+)/?([^/]*)"))

(fn M.setup! []
  "Define thyme rollback commands."
  (let [complete-dirs (fn [arg-lead _cmdline _cursorpos]
                        (let [root (RollbackManager.get-root)
                              prefix-length (+ 2 (length root))
                              glob-pattern (Path.join root (.. arg-lead "**/"))
                              paths (vim.fn.glob glob-pattern false true)]
                          (icollect [_ path (ipairs paths)]
                            ;; Trim root prefix and trailing `/`.
                            (path:sub prefix-length -2))))]
    (command! :ThymeRollbackSwitch
      {:nargs 1
       :complete complete-dirs
       :desc "[thyme] Prompt to select rollback for compile error"}
      (fn [{:args input}]
        (let [root (RollbackManager.get-root)
              prefix (Path.join root input)
              glob-pattern (Path.join prefix "*.{lua,fnl}")
              candidates (vim.fn.glob glob-pattern false true)]
          (case (length candidates)
            0 (vim.notify (.. "Abort. No backup is found for " input))
            1 (vim.notify (.. "Abort. Only one backup is found for " input))
            _ (do
                (table.sort candidates #(< $2 $1))
                (vim.ui.select candidates ;
                               {:prompt (-> "Select rollback for %s: "
                                            (: :format input))
                                :format_item (fn [path]
                                               (let [basename (vim.fs.basename path)]
                                                 (if (RollbackManager.active-backup? path)
                                                     (.. basename " (current)")
                                                     basename)))}
                               (fn [?backup-path]
                                 (if ?backup-path
                                     (do
                                       (RollbackManager.switch-active-backup! ?backup-path)
                                       (vim.cmd :ThymeCacheClear))
                                     (vim.notify "Abort selecting rollback target")))))))))
    (command! :ThymeRollbackMount
      {:nargs 1
       :complete complete-dirs
       :desc "[thyme] Mount currently active backup"}
      (fn [{: args}]
        (case (RollbackCommandBackend.cmdargs->kind-modname args)
          (kind modname) (if (RollbackCommandBackend.mount-backup! kind modname)
                             (vim.notify (.. "Successfully mounted " args)
                                         vim.log.levels.INFO)
                             (vim.notify (.. "Failed to mount " args)
                                         vim.log.levels.WARN)))))
    (command! :ThymeRollbackUnmount
      {:nargs "?"
       ;; TODO: Complete only mounted backups.
       :complete complete-dirs
       :desc "[thyme] Unmount mounted backup"}
      (fn [{: args}]
        (case (RollbackCommandBackend.cmdargs->kind-modname args)
          (kind modname)
          (case (pcall RollbackCommandBackend.unmount-backup! kind modname)
            (false msg) (vim.notify (-> "Failed to mount %s:\n%s"
                                        (: :format args msg))
                                    vim.log.levels.WARN)
            _ (vim.notify (.. "Successfully unmounted " args)
                          vim.log.levels.INFO)))))
    (command! :ThymeRollbackUnmountAll
      {:nargs 0 :desc "[thyme] Unmount all the mounted backups"}
      (fn []
        (case (pcall RollbackManager.unmount-backup-all!)
          (false msg) (vim.notify (-> "Failed to mount backups:\n%s"
                                      (: :format msg))
                                  vim.log.levels.WARN)
          _ (vim.notify (.. "Successfully unmounted all the backups")
                        vim.log.levels.INFO))))))

M
