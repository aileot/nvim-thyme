(import-macros {: command!} :thyme.macros)

(local Path (require :thyme.util.path))
(local Messenger (require :thyme.util.class.messenger))
(local CommandMessenger (Messenger.new "command/rollback"))
(local RollbackManager (require :thyme.rollback.manager))

(local M {})

(local RollbackCommander {})

(fn RollbackCommander.cmdargs->kind-modname [cmdargs]
  "Parse cmdargs (slash-separated) into two strings: `kind` and `modname`.
@param cmdargs string
@return kind string
@return modname string an empty string will indicates all the stored modulesof the `kind`."
  (cmdargs:match "([^/]+)/?([^/]*)"))

(λ RollbackCommander.attach [kind]
  "Create a RollbackManager instance only to attach to the data stored for
`kind`.
@return RollbackManager"
  (let [ext-tmp ".tmp"]
    (RollbackManager.new kind ext-tmp)))

(fn RollbackCommander.get-root [kind modname]
  "Get the root directory of the backup files for `modname` of the `kind`.
@param kind string
@param modname string an empty string indicates all the backups in the `kind`
@return string"
  (-> (RollbackCommander.attach kind)
      (: :backup-handler-of modname)
      (: :determine-backup-dir)))

(fn RollbackCommander.list-backups [kind modname]
  (let [dir (RollbackCommander.get-root kind modname)
        glob-pattern (Path.join dir "*.{lua,fnl}")
        candidates (vim.fn.glob glob-pattern false true)]
    candidates))

(fn RollbackCommander.switch-active-backup! [kind modname path]
  "Mount currently active backup for `modname` of the `kind`.
@param kind string
@param modname string an empty string indicates all the backups in the `kind`
@param path string the path to the new active backup"
  (-> (RollbackCommander.attach kind)
      (: :backup-handler-of modname)
      (: :switch-active-backup! path)))

(fn RollbackCommander.mount-backup! [kind modname]
  "Mount currently active backup for `modname` of the `kind`.
@param kind string
@param modname string an empty string indicates all the backups in the `kind`"
  (-> (RollbackCommander.attach kind)
      (: :backup-handler-of modname)
      (: :mount-backup!)))

(fn RollbackCommander.unmount-backup! [kind modname]
  "Unmount previously mounted backup for `backup-dir`.
@param backup-dir string"
  (-> (RollbackCommander.attach kind)
      (: :backup-handler-of modname)
      (: :unmount-backup!)))

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
      (fn [{: args}]
        (case-try (RollbackCommander.cmdargs->kind-modname args)
          (kind modname) (-> (RollbackCommander.attach kind)
                             (: :backup-handler-of modname)
                             (: :list-backup-files))
          candidates (case (length candidates)
                       0 (error (.. "Abort. No backup is found for " args))
                       1 (CommandMessenger:notify! (.. "Abort. Only one backup is found for "
                                                       args)
                                                   vim.log.levels.WARN)
                       _ (do
                           (table.sort candidates #(< $2 $1))
                           (vim.ui.select candidates ;
                                          {:prompt (-> "Select rollback for %s: "
                                                       (: :format args))
                                           :format_item (fn [path]
                                                          (let [basename (vim.fs.basename path)]
                                                            (if (RollbackManager.active-backup? path)
                                                                (.. basename
                                                                    " (current)")
                                                                basename)))}
                                          (fn [?backup-path]
                                            (if ?backup-path
                                                (RollbackCommander.switch-active-backup! kind
                                                                                         modname
                                                                                         ?backup-path)
                                                (CommandMessenger:notify! "Abort selecting rollback target")))))))))
    (command! :ThymeRollbackMount
      {:nargs 1
       :complete complete-dirs
       :desc "[thyme] Mount currently active backup"}
      (fn [{: args}]
        (case (RollbackCommander.cmdargs->kind-modname args)
          (kind modname) (RollbackCommander.mount-backup! kind modname)))))
  (let [complete-mounted (fn [arg-lead _cmdline _cursorpos]
                           ;; HACK: Every expressions are hardcoded apart from
                           ;; the class methods, but does it so matter for
                           ;; dedicated command-complete functions?
                           (let [root (RollbackManager.get-root)
                                 prefix-length (+ 2 (length root))
                                 mounted-filename ".mounted"
                                 glob-patternn (Path.join root
                                                          (.. arg-lead "**/"
                                                              mounted-filename))
                                 paths (vim.fn.glob glob-patternn false true)]
                             (icollect [_ path (ipairs paths)]
                               ;; Trim root prefix, and trailing `/` and the .mounted filename.
                               (path:sub prefix-length
                                         (- -2 (length mounted-filename))))))]
    (command! :ThymeRollbackUnmount
      {:nargs "?"
       :complete complete-mounted
       :desc "[thyme] Unmount mounted backup"}
      (fn [{: args}]
        (case (RollbackCommander.cmdargs->kind-modname args)
          (kind modname) (RollbackCommander.unmount-backup! kind modname))))
    (command! :ThymeRollbackUnmountAll
      {:nargs 0 :desc "[thyme] Unmount all the mounted backups"}
      (fn []
        (case (pcall RollbackManager.unmount-backup-all!)
          (false msg) (CommandMessenger:notify! (-> "Failed to mount backups:\n%s")
                                                (: :format msg
                                                   vim.log.levels.WARN))
          _ (CommandMessenger:notify! (.. "Successfully unmounted all the backups")
                                      vim.log.levels.INFO))))))

M
