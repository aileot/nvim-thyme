(import-macros {: when-not : last} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: file-readable?
        : assert-is-file-readable
        : assert-is-directory
        : read-file
        &as fs} (require :thyme.utils.fs))

(local {: state-prefix} (require :thyme.const))

(local {: hide-file! : has-hidden-file? : restore-file!}
       (require :thyme.utils.pool))

(local Rollback {:_backup-dir (Path.join state-prefix :rollbacks)
                 :_active-backup-filename ".active"
                 :_pinned-backup-filename ".pinned"})

(set Rollback.__index Rollback)

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

(λ Rollback.new [label file-extension]
  (let [self (setmetatable {} Rollback)
        root (Path.join Rollback._backup-dir label)]
    (vim.fn.mkdir root :p)
    (set self.root root)
    (assert (= "." (file-extension:sub 1 1))
            "file-extension must start with `.`")
    (set self.file-extension file-extension)
    self))

(fn Rollback.module-name->backup-dir [self module-name]
  "Return module backed up directory.
@param module-name string
@return string backup directory for the module"
  (let [dir (Path.join self.root module-name)]
    dir))

(fn Rollback.module-name->new-backup-path [self module-name]
  "Return module new backed up path for `module-name`.
@param module-name string
@return string the module backup path"
  (let [rollback-id (os.date "%Y-%m-%d_%H-%M-%S")
        backup-filename (.. rollback-id self.file-extension)
        backup-dir (self:module-name->backup-dir module-name)]
    (vim.fn.mkdir backup-dir :p)
    (Path.join backup-dir backup-filename)))

(fn Rollback.module-name->active-backup-path [self module-name]
  "Return module the active backed up path.
@param module-name string
@return string? the module backup path, or nil if not found"
  (let [backup-dir (self:module-name->backup-dir module-name)
        active-backup-filename Rollback._active-backup-filename]
    (Path.join backup-dir active-backup-filename)))

(fn Rollback.should-update-backup? [self module-name expected-contents]
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

(fn Rollback.create-module-backup! [self module-name path]
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

(fn Rollback.get-root []
  "Return the root directory of backup files.
@return string the root path"
  Rollback._backup-dir)

(λ Rollback.switch-active-backup! [backup-path]
  "Switch active backup to `backup-path`."
  (assert-is-file-readable backup-path)
  (let [dir (vim.fs.dirname backup-path)
        active-backup-path (Path.join dir Rollback._active-backup-filename)]
    (symlink! backup-path active-backup-path)))

(fn Rollback.active-backup? [backup-path]
  "Tell if given `backup-path` is an active backup.
@param backup-path string
@return boolean"
  (assert-is-file-readable backup-path)
  (let [dir (vim.fs.dirname backup-path)
        active-backup-path (Path.join dir Rollback._active-backup-filename)]
    (= backup-path (fs.readlink active-backup-path))))

(fn Rollback.pin-backup! [backup-dir]
  "Pin currently active backup for `backup-dir`.
@param backup-dir string"
  (assert-is-directory backup-dir)
  (let [active-backup-path (Path.join backup-dir
                                      Rollback._active-backup-filename)
        pinned-backup-path (Path.join backup-dir
                                      Rollback._pinned-backup-filename)]
    (symlink! active-backup-path pinned-backup-path)))

(fn Rollback.unpin-backup! [backup-dir]
  "Unpin previously pinned backup for `backup-dir`.
@param backup-dir string"
  (assert-is-directory backup-dir)
  (let [pinned-backup-path (Path.join backup-dir Rollback._pinned-backup-prefix)]
    (assert-is-file-readable pinned-backup-path)
    (assert (fs.unlink pinned-backup-path))))

Rollback
