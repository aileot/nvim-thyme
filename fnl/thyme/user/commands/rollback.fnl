(import-macros {: command!} :thyme.macros)

(local Path (require :thyme.utils.path))

(local RollbackManager (require :thyme.rollback))

(local M {})

(local RollbackCommandBackend {})

(λ RollbackCommandBackend.attach [kind]
  "Create a RollbackManager instance only to attach to the data stored for
`kind`.
@return RollbackManager"
  (let [ext-tmp ".tmp"]
    (RollbackManager.new kind ext-tmp)))

(fn RollbackCommandBackend.mount-backup! [kind module-name]
  "Mount currently active backup for `module-name` of the `kind`.
@param kind string
@param module-name string an empty string indicates all the backups in the `kind`"
  (let [ext-tmp ".tmp"
        backup-handler (-> (RollbackCommandBackend.attach kind ext-tmp)
                           (: :backupHandlerOf module-name))]
    (backup-handler:mount-backup!)))

(fn RollbackCommandBackend.cmdargs->kind-modname [cmdargs]
  "Parse cmdargs (slash-separated) into two strings: `kind` and `module-name`.
@param cmdargs string
@return kind string
@return module-name string an empty string will indicates all the stored modulesof the `kind`."
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
          (kind module-name) (if (RollbackCommandBackend.mount-backup! kind
                                                                       module-name)
                                 (vim.notify (.. "Successfully mounted " args)
                                             vim.log.levels.INFO)
                                 (vim.notify (.. "Failed to mount " args)
                                             vim.log.levels.WARN)))))
    (command! :ThymeRollbackUnmount
      {:nargs "?"
       ;; TODO: Complete only mounted backups.
       :complete complete-dirs
       :desc "[thyme] Unmount mounted backup"}
      (fn [{:args input}]
        (let [root (RollbackManager.get-root)
              dir (Path.join root input)]
          (case (pcall RollbackManager.unmount-backup! dir)
            (false msg) (vim.notify (-> "Failed to mount %s:\n%s"
                                        (: :format dir msg))
                                    vim.log.levels.WARN)
            _ (vim.notify (.. "Successfully unmounted " dir)
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
