(local Path (require :thyme.utils.path))

(local {: file-readable? : read-file &as fs} (require :thyme.utils.fs))

(local {: hide-file! : has-hidden-file? : restore-file!}
       (require :thyme.utils.pool))

(local RollbackModuleHandler {})

(set RollbackModuleHandler.__index RollbackModuleHandler)

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

(fn RollbackModuleHandler.new [root-dir module-name]
  (let [attrs {:_active-backup-filename ".active"
               :_mounted-backup-filename ".mounted"}
        self (setmetatable attrs RollbackModuleHandler)]
    (set self._root-dir root-dir)
    (set self._module-name module-name)
    self))

(fn RollbackModuleHandler.module-name->backup-dir [self]
  "Return backup directory for `module-name`.
@return string the backup directory"
  (let [dir (Path.join self._root-dir self._module-name)]
    dir))

(fn RollbackModuleHandler.module-name->backup-files [self]
  "Return backup files for `module-name`. The special files like `.active` and
`.mounted` are ignored.
@return string[] backup files"
  (let [backup-dir (self:module-name->backup-dir self._module-name)]
    (-> (Path.join backup-dir "*")
        (vim.fn.glob false true))))

(fn RollbackModuleHandler.module-name->new-backup-path [self]
  "Suggest a new backup path for `module-name`. This method does not create the
path by itself.
@return string a new backup path"
  (let [rollback-id (-> (os.date "%Y-%m-%d_%H-%M-%S")
                        ;; NOTE: os.date does not interpret `%N` for nanoseconds.
                        (.. "_" (vim.uv.hrtime)))
        backup-filename (.. rollback-id self.file-extension)
        backup-dir (self:module-name->backup-dir self._module-name)]
    (vim.fn.mkdir backup-dir :p)
    (Path.join backup-dir backup-filename)))

(fn RollbackModuleHandler.module-name->active-backup-path [self]
  "Return the active backup path for `module-name`.
@return string? the active backup path, or nil if not found"
  (let [backup-dir (self:module-name->backup-dir self._module-name)
        filename RollbackModuleHandler._active-backup-filename]
    (Path.join backup-dir filename)))

(fn RollbackModuleHandler.module-name->active-backup-birthtime [self]
  "Return the active backup creation time for `module-name`.
@return string? the birthtime of the active backup, or nil if not found"
  (case (-?> (self:module-name->active-backup-path self._module-name)
             (fs.stat)
             (. :birthtime :sec))
    time (os.date "%c" time)))

(fn RollbackModuleHandler.module-name->mounted-backup-path [self]
  "Return the mounted backupup path for `module-name`.
Note that mounted backup is linked to an active backup so that the contents are
always the same.
@return string? the mounted backup path, or nil if not found"
  (let [backup-dir (self:module-name->backup-dir self._module-name)
        filename RollbackModuleHandler._mounted-backup-filename]
    (Path.join backup-dir filename)))

(fn RollbackModuleHandler.should-update-backup? [self expected-contents]
  "Check if the backup of the module should be updated.
Return `true` if the following conditions are met:

- `expected-contents` is different from the backed-up contents for the
  module.

@param expected-contents string contents expected for the module
@return boolean true if module should be backed up, false otherwise"
  (let [module-name self._module-name]
    (assert (not (file-readable? module-name))
            (.. "expected module-name, got path " module-name))
    (let [backup-path (self:module-name->active-backup-path module-name)]
      (or (not (file-readable? backup-path))
          (not= (read-file backup-path)
                (assert expected-contents
                        "expected non empty string for `expected-contents`"))))))

(fn RollbackModuleHandler.create-module-backup! [self path]
  "Create a backup file of `path` as `module-name`.
@param path string"
  ;; NOTE: Saving a chunk of macro module is probably impossible.
  (assert (file-readable? path) (.. "expected readable file, got " path))
  (let [module-name self._module-name
        backup-path (self:module-name->new-backup-path module-name)
        active-backup-path (self:module-name->active-backup-path module-name)]
    (-> (vim.fs.dirname active-backup-path)
        (vim.fn.mkdir :p))
    (assert (fs.copyfile path backup-path))
    (symlink! backup-path active-backup-path)))

(fn RollbackModuleHandler.search-module-from-mounted-backups [self]
  "Search for `module-name` in mounted rollbacks.
@return string|(fun(): table)|nil a lua chunk, but, for macro searcher, only expects a macro table as its end; otherwise, returns `nil` preceding an error message in the second return value for macro searcher; return error message for module searcher.
@return nil|string: nil, or (only for macro searcher) an error message."
  (let [module-name self._module-name
        rollback-path (self:module-name->mounted-backup-path module-name)
        loader-name (-> "thyme-mounted-rollback-%s-loader"
                        (: :format self._kind))]
    (if (file-readable? rollback-path)
        (let [resolved-path (fs.readlink rollback-path)
              msg (-> "%s: rollback to mounted backup for %s %s (created at %s)"
                      (: :format loader-name self._kind module-name module-name
                         (self:module-name->active-backup-birthtime module-name)))]
          (vim.notify_once msg vim.log.levels.WARN)
          ;; TODO: Is it redundant to resolve path for error message?
          (loadfile resolved-path))
        (let [error-msg (-> "%s: no mounted backup is found for %s %s"
                            (: :format loader-name self._kind module-name))]
          (if (= self._kind "macro")
              ;; TODO: Better implementation independent of `self._kind`.
              (values nil error-msg)
              error-msg)))))

RollbackModuleHandler
