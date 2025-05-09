(import-macros {: when-not : inc : first : last} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: file-readable? : assert-is-file-readable &as fs}
       (require :thyme.utils.fs))

(local {: state-prefix} (require :thyme.const))

(local {: hide-file! : has-hidden-file? : restore-file!}
       (require :thyme.utils.pool))

(local BackupHandler (require :thyme.rollback.backup-handler))

(local RollbackManager
       {:_root (Path.join state-prefix :rollbacks)
        :_active-backup-filename ".active"
        :_mounted-backup-filename ".mounted"})

(set RollbackManager.__index RollbackManager)

(fn symlink! [path new-path ...]
  "Force create symbolic link from `path` to `new-path`.
@param path string
@param new-path string
@return boolean true if symlink is successfully created, or false"
  (when (file-readable? new-path)
    (hide-file! new-path))
  (case (pcall (assert #(vim.uv.fs_symlink path new-path)))
    (false msg) (if (has-hidden-file? new-path)
                    true
                    (do
                      (restore-file! new-path)
                      (vim.notify msg vim.log.levels.ERROR)
                      false))
    _ true))

;;; Class Methods

(fn RollbackManager.backupHandlerOf [self module-name]
  "Create a rollback handler for `module-name`
@param module-name string
@return BackupHandler"
  (BackupHandler.new self._kind-dir self.file-extension module-name))

(fn RollbackManager.arrange-loader-path [self old-loader-path]
  "Return loader path updated for mounted rollback feature.
@param old-loader-path string
@return string"
  (let [loader-path-for-mounted-backups (Path.join self._kind-dir "?"
                                                   self._mounted-backup-filename)
        loader-prefix (.. loader-path-for-mounted-backups ";")]
    ;; Keep mounted backup loader path at the beginning of loader path.
    (case (old-loader-path:find loader-path-for-mounted-backups 1 true)
      1 old-loader-path
      nil (.. loader-prefix old-loader-path)
      (idx-start idx-end) (let [tmp-loader-path (.. (old-loader-path:sub 1
                                                                         idx-start)
                                                    (old-loader-path:sub idx-end))]
                            (.. loader-prefix tmp-loader-path)))))

(fn RollbackManager.search-module-from-mounted-backups [self module-name]
  "Search for `module-name` in mounted rollbacks.
@param module-name string
@return string|(fun(): table)|nil a lua chunk, but, for macro searcher, only expects a macro table as its end; otherwise, returns `nil` preceding an error message in the second return value for macro searcher; return error message for module searcher.
@return nil|string: nil, or (only for macro searcher) an error message."
  (let [backup-handler (self:backupHandlerOf module-name)
        rollback-path (backup-handler:determine-mounted-backup-path)
        loader-name (-> "thyme-mounted-rollback-%s-loader"
                        (: :format self._kind))]
    (if (file-readable? rollback-path)
        (let [resolved-path (fs.readlink rollback-path)
              msg (-> "%s: rollback to backup for %s (created at %s)"
                      (: :format loader-name module-name
                         (backup-handler:determine-active-backup-birthtime module-name)))]
          (vim.notify_once msg vim.log.levels.WARN)
          ;; TODO: Is it redundant to resolve path for error message?
          (loadfile resolved-path))
        (let [error-msg (-> "%s: no mounted backup is found for %s %s"
                            (: :format loader-name self._kind module-name))]
          (if (= self._kind "macro")
              ;; TODO: Better implementation independent of `self._kind`.
              (values nil error-msg)
              error-msg)))))

(fn RollbackManager.inject-mounted-backup-searcher! [self searchers]
  "Inject mounted backup searcher into `searchers` in the highest priority.
@param searchers function[]
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
    (symlink! backup-path active-backup-path)))

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
