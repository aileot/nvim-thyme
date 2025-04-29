(import-macros {: when-not : last} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: file-readable? : assert-is-file-readable : read-file &as fs}
       (require :thyme.utils.fs))

(local {: state-prefix} (require :thyme.const))

(local {: hide-file! : has-hidden-file? : restore-file!}
       (require :thyme.utils.pool))

(local RollbackManager
       {:_backup-dir (Path.join state-prefix :rollbacks)
        :_active-backup-filename ".active"
        :_pinned-backup-filename ".pinned"
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

(fn RollbackManager.module-name->backup-dir [self module-name]
  "Return module backed up directory.
@param module-name string
@return string backup directory for the module"
  (let [dir (Path.join self.root module-name)]
    dir))

(fn RollbackManager.module-name->new-backup-path [self module-name]
  "Return module new backed up path for `module-name`.
@param module-name string
@return string the module backup path"
  (let [rollback-id (os.date "%Y-%m-%d_%H-%M-%S")
        backup-filename (.. rollback-id self.file-extension)
        backup-dir (self:module-name->backup-dir module-name)]
    (vim.fn.mkdir backup-dir :p)
    (Path.join backup-dir backup-filename)))

(fn RollbackManager.module-name->active-backup-path [self module-name]
  "Return module the active backed up path.
@param module-name string
@return string? the module backup path, or nil if not found"
  (let [backup-dir (self:module-name->backup-dir module-name)
        active-backup-filename RollbackManager._active-backup-filename]
    (Path.join backup-dir active-backup-filename)))

(fn RollbackManager.should-update-backup? [self module-name expected-contents]
  "Check if the backup of the module should be updated.
Return `true` if the following conditions are met:

- `expected-contents` is different from the backed-up contents for the
  module.

@param module-name string
@param expected-contents string contents expected for the module
@return boolean true if module should be backed up, false otherwise"
  (assert (not (file-readable? module-name))
          (.. "expected module-name, got path " module-name))
  (let [backup-path (self:module-name->active-backup-path module-name)]
    (or (not (file-readable? backup-path))
        (not= (read-file backup-path)
              (assert expected-contents
                      "expected non empty string for `expected-contents`")))))

(fn RollbackManager.create-module-backup! [self module-name path]
  "Create a backup file of `path` as `module-name`.
@param module-name string
@param path string"
  ;; NOTE: Saving a chunk of macro module is probably impossible.
  (assert (file-readable? path) (.. "expected readable file, got " path))
  (let [backup-path (self:module-name->new-backup-path module-name)
        active-backup-path (self:module-name->active-backup-path module-name)]
    (-> (vim.fs.dirname active-backup-path)
        (vim.fn.mkdir :p))
    (assert (fs.copyfile path backup-path))
    (symlink! backup-path active-backup-path)))

(fn RollbackManager.arrange-loader-path [self old-loader-path]
  "Return loader path updated for mounted rollback feature.
@param old-loader-path string
@return string"
  (let [loader-path-for-mounted-backups (Path.join self.root "?"
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

;;; Static Methods

(λ RollbackManager.new [label file-extension]
  (let [self (setmetatable {} RollbackManager)
        root (Path.join RollbackManager._backup-dir label)]
    (vim.fn.mkdir root :p)
    (set self.root root)
    (assert (= "." (file-extension:sub 1 1))
            "file-extension must start with `.`")
    (set self.file-extension file-extension)
    self))

(fn RollbackManager.get-root []
  "Return the root directory of backup files.
@return string the root path"
  RollbackManager._backup-dir)

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

(fn RollbackManager.pin-backup! [backup-dir]
  "Pin currently active backup for `backup-dir`.
@param backup-dir string"
  (let [active-backup-path (Path.join backup-dir
                                      RollbackManager._active-backup-filename)
        pinned-backup-path (Path.join backup-dir
                                      RollbackManager._pinned-backup-filename)]
    (symlink! active-backup-path pinned-backup-path)))

(fn RollbackManager.unpin-backup! [backup-dir]
  "Unpin previously pinned backup for `backup-dir`.
@param backup-dir string"
  (let [pinned-backup-path (Path.join backup-dir
                                      RollbackManager._pinned-backup-prefix)]
    (assert-is-file-readable pinned-backup-path)
    (assert (fs.unlink pinned-backup-path))))

(fn RollbackManager.mount-backup! [backup-dir]
  "Mount currently active backup for `backup-dir`.
@param backup-dir string"
  (let [active-backup-path (Path.join backup-dir
                                      RollbackManager._active-backup-filename)
        mountned-backup-path (Path.join backup-dir
                                        RollbackManager._mountned-backup-filename)]
    (symlink! active-backup-path mountned-backup-path)))

(fn RollbackManager.unmount-backup! [backup-dir]
  "Unmount previously mounted backup for `backup-dir`.
@param backup-dir string"
  (let [mountned-backup-path (Path.join backup-dir
                                        RollbackManager._mountned-backup-prefix)]
    (assert-is-file-readable mountned-backup-path)
    (assert (fs.unlink mountned-backup-path))))

RollbackManager
