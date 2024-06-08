(import-macros {: when-not} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: file-readable? : read-file &as fs} (require :thyme.utils.fs))

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

(fn BackupManager.module-name->backup-path [self module-name]
  "Return module backed up path.
@param module-name string
@return string backup path"
  (Path.join self.root module-name))

(fn BackupManager.should-backup-module? [self module-name expected-contents]
  (assert (not (file-readable? module-name))
          (.. "expected module-name, got path " module-name))
  (let [backup-path (self:module-name->backup-path module-name)]
    (or (not (file-readable? backup-path))
        (not= (read-file backup-path)
              (assert expected-contents
                      "expected non empty string for `expected-contents`")))))

(fn BackupManager.backup-module! [self module-name path]
  "Create a backup file of `path` for `module-name`.
@param module-name string
@param path string"
  ;; Note: Saving a chunk of macro module is probably impossible.
  (assert (file-readable? path) (.. "expected readable file, got " path))
  (let [backup-path (self:module-name->backup-path module-name)]
    (assert (fs.copyfile path backup-path))))

(fn BackupManager.get-root []
  "Return the root directory of backup files.
@return string the root path"
  backup-prefix)

BackupManager
