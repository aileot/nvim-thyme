(import-macros {: when-not : last} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: directory? : file-readable? : read-file &as fs}
       (require :thyme.utils.fs))

(local {: state-prefix} (require :thyme.const))

(local backup-prefix (Path.join state-prefix :backup))

(local BackupManager {})

(set BackupManager.__index BackupManager)

(fn BackupManager.new [label]
  (let [self (setmetatable {} BackupManager)
        root (Path.join backup-prefix label)]
    (vim.fn.mkdir root :p)
    (set self.root root)
    self))

(fn BackupManager.module-name->backup-dir [self module-name]
  "Return module backed up directory.
@param module-name string
@return string backup directory for the module"
  (let [dir (Path.join self.root module-name)]
    dir))

(fn BackupManager.module-name->new-backup-path [self module-name]
  "Return module new backed up path for `module-name`.
@param module-name string
@return string the module backup path"
  (let [rollback-id (os.date "%Y-%m-%d_%H-%M-%S")
        backup-dir (self:module-name->backup-dir module-name)]
    (vim.fn.mkdir backup-dir :p)
    (Path.join backup-dir rollback-id)))

(fn BackupManager.module-name->?current-backup-path [self module-name]
  "Return module the current backed up path.
@param module-name string
@return string? the module backup path, or nil if not found"
  (let [backup-dir (self:module-name->backup-dir module-name)]
    (when (directory? backup-dir)
      (let [files (vim.fn.readdir backup-dir)
            rollback-id (last files)
            backup-path (Path.join backup-dir rollback-id)]
        (when (file-readable? backup-path)
          backup-path)))))

(fn BackupManager.should-update-backup? [self module-name expected-contents]
  "Check if the backup of the module should be updated.
Return `true` if the following conditions are met:

- `expected-contents` is different from the backed-up contents for the
  module.

@param module-name string
@param expected-contents string contents expected for the module
@return boolean true if module should be backed up, false otherwise"
  (assert (not (file-readable? module-name))
          (.. "expected module-name, got path " module-name))
  (case (self:module-name->?current-backup-path module-name)
    nil true
    backup-path (not= (read-file backup-path)
                      (assert expected-contents
                              "expected non empty string for `expected-contents`"))))

(fn BackupManager.create-module-backup! [self module-name path]
  "Create a backup file of `path` as `module-name`.
@param module-name string
@param path string"
  ;; NOTE: Saving a chunk of macro module is probably impossible.
  (assert (file-readable? path) (.. "expected readable file, got " path))
  (let [backup-path (self:module-name->new-backup-path module-name)]
    (-> (vim.fs.dirname backup-path)
        (vim.fn.mkdir :p))
    (assert (fs.copyfile path backup-path))))

(fn BackupManager.get-root []
  "Return the root directory of backup files.
@return string the root path"
  backup-prefix)

BackupManager
