(import-macros {: when-not : inc : first : last} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: file-readable? : assert-is-file-readable &as fs}
       (require :thyme.utils.fs))

(local {: state-prefix} (require :thyme.const))

(local Messenger (require :thyme.utils.messenger))

(local BackupHandler (require :thyme.rollback.backup-handler))

(local RollbackManager
       {:_root (Path.join state-prefix :rollbacks)
        :_active-backup-filename ".active"
        :_mounted-backup-filename ".mounted"})

(set RollbackManager.__index RollbackManager)

;;; Class Methods

(fn RollbackManager.backup-handler-of [self module-name]
  "Create a rollback handler for `module-name`
@param module-name string
@return BackupHandler"
  (BackupHandler.new self._kind-dir self.file-extension module-name))

(fn RollbackManager.search-module-from-mounted-backups [self module-name]
  "Search for `module-name` in mounted rollbacks.
@param module-name string
@return string|(fun(): table)|nil a lua chunk, but, for macro searcher, only expects a macro table as its end; otherwise, returns `nil` preceding an error message in the second return value for macro searcher; return error message for module searcher.
@return nil|string: nil, or (only for macro searcher) an error message."
  (let [backup-handler (self:backup-handler-of module-name)
        rollback-path (backup-handler:determine-mounted-backup-path)
        messenger (Messenger.new (-> "rollback/mounted/loader/%s"
                                     (: :format self._kind)))]
    (if (file-readable? rollback-path)
        (let [msg (-> "rollback to backup for %s/%s (created at %s)"
                      (: :format self._kind module-name
                         (backup-handler:determine-active-backup-birthtime module-name)))]
          (messenger:notify-once! msg vim.log.levels.WARN)
          ;; HACK: For module searcher, the Lua builtin `loadfile` does not
          ;; interpret the second param, but just ignore it; for macro searcher,
          ;; `fennel.eval` wrapper require both `module-name` and `fnl-path`.
          (self._file-loader rollback-path module-name))
        (let [error-msg (-> "no mounted backup is found for %s %s"
                            (: :format self._kind module-name)
                            (messenger:wrap-msg))]
          (if (= self._kind "macro")
              ;; TODO: Better implementation independent of `self._kind`.
              (values nil error-msg)
              error-msg)))))

(fn RollbackManager.inject-mounted-backup-searcher! [self searchers loader]
  "Inject mounted backup searcher into `searchers` in the highest priority.
@param searchers function[]
@param loader fun(path, nil, compiler-options, module-name)
@return function? the mounted searcher if `searchers` is not yet injected."
  ;; TODO: Add option to avoid injecting searcher more than once in case where
  ;; some other plugin injects other searchers only to fall into infinite loop.
  (if (not self._injected-searcher)
      (do
        (set self._injected-searcher
             ;; NOTE: Otherwise, i.e., directly injecting
             ;; self.search-module-from-mounted-backups will fail to get `self`
             ;; as the first argument, but only get module-name as the first
             ;; argument and `nil` as the second argument.
             (partial self.search-module-from-mounted-backups self))
        (set self._file-loader loader)
        (table.insert searchers 1 self._injected-searcher)
        self._injected-searcher)
      (not= (first searchers) self._injected-searcher)
      (do
        (faccumulate [dropped? false i 1 (length searchers) &until dropped?]
          (if (= (. searchers i) self._injected-searcher)
              (table.remove searchers i)
              false))
        (table.insert searchers 1 self._injected-searcher))))

;;; Static Methods

(λ RollbackManager.new [kind file-extension]
  "Create a new RollbackManager.
@param kind string for internal capsulation on filesystem
@param file-extension string
@return RollbackManager"
  (let [self (setmetatable {} RollbackManager)
        root (Path.join RollbackManager._root kind)]
    (vim.fn.mkdir root :p)
    (set self._kind kind)
    (set self._kind-dir root)
    (set self._file-loader {})
    (assert (= "." (file-extension:sub 1 1))
            "file-extension must start with `.`")
    (set self.file-extension file-extension)
    self))

(fn RollbackManager.get-root []
  "Return the root directory of backup files.
@return string the root path"
  RollbackManager._root)

(λ RollbackManager.switch-active-backup! [backup-path]
  "Switch active backup to `backup-path`."
  (assert-is-file-readable backup-path)
  (let [dir (vim.fs.dirname backup-path)
        active-backup-path (Path.join dir
                                      RollbackManager._active-backup-filename)]
    (fs.symlink! backup-path active-backup-path)))

(fn RollbackManager.active-backup? [backup-path]
  "Tell if given `backup-path` is an active backup.
@param backup-path string
@return boolean"
  (assert-is-file-readable backup-path)
  (let [dir (vim.fs.dirname backup-path)
        active-backup-path (Path.join dir
                                      RollbackManager._active-backup-filename)]
    (= backup-path (fs.readlink active-backup-path))))

(fn RollbackManager.list-mounted-paths []
  "Return all the mounted rollback paths.
@return string[] the list of mounted paths"
  (-> (Path.join RollbackManager._root ;
                 "*" ; for rollback kind
                 "*" ; for module
                 RollbackManager._mounted-backup-filename)
      (vim.fn.glob false true)))

(fn RollbackManager.unmount-backup-all! []
  "Unmount all the mounted backups.
@return boolean true if all the mounted backups are successfully unmounted, or no backup has been mounted; false otherwise"
  (case (RollbackManager.list-mounted-paths)
    mounted-backup-paths (each [_ path (ipairs mounted-backup-paths)]
                           (assert (fs.unlink path))))
  true)

RollbackManager
