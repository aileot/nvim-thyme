(import-macros {: inc} :thyme.macros)

(local {: lua-cache-prefix} (require :thyme.const))

(local {: validate-type : sorter/files-to-oldest-by-birthtime}
       (require :thyme.util.general))

(local Path (require :thyme.util.path))

(local {: file-readable?
        : assert-is-file-readable
        : assert-is-symlink
        : read-file
        &as fs} (require :thyme.util.fs))

(local BackupHandler {})

(set BackupHandler.__index BackupHandler)

(fn BackupHandler.new [root-dir file-extension module-name]
  "Create a new BackupHandler for `module-name`.
@param root-dir string
@param file-extension string
@param module-name string
@return BackupHandler"
  (let [attrs {:_latest-cache-linkname ".latest"
               :_active-backup-filename ".active"
               :_mounted-backup-filename ".mounted"}
        self (setmetatable attrs BackupHandler)]
    (set self._root-dir root-dir)
    (set self._file-extension file-extension)
    (set self._module-name module-name)
    self))

(fn BackupHandler.determine-backup-dir [self]
  "Return backup directory for `module-name`.
@return string the backup directory"
  (let [dir (Path.join self._root-dir self._module-name)]
    dir))

(fn BackupHandler.list-backup-files [self]
  "Return a list of backup files for `module-name`. The special files like `.active` and
`.mounted` are ignored.
@return string[] backup files"
  (let [backup-dir (self:determine-backup-dir)]
    (-> (Path.join backup-dir "*")
        (vim.fn.glob false true))))

(fn BackupHandler.suggest-new-backup-path [self]
  "Suggest a new backup path for `module-name`. This method does not create the
path by itself.
@return string a new backup path"
  (let [rollback-id (-> (os.date "%Y-%m-%d_%H-%M-%S")
                        ;; NOTE: os.date does not interpret `%N` for nanoseconds.
                        (.. "_" (vim.uv.hrtime)))
        backup-filename (.. rollback-id self._file-extension)
        backup-dir (self:determine-backup-dir)]
    (vim.fn.mkdir backup-dir :p)
    (Path.join backup-dir backup-filename)))

(fn BackupHandler.determine-latest-cache-link-path [self]
  "Determine the link path to the latest cache for `module-name`.
@return string the link path"
  (let [backup-dir (self:determine-backup-dir)
        filename self._latest-cache-linkname]
    (Path.join backup-dir filename)))

(fn BackupHandler.update-latest-cache-link! [self cache-path]
  "Update the link to the `cache-path` for `module-name`."
  (let [link-path (self:determine-latest-cache-link-path)]
    ;; NOTE: The config .nvim-thyme.fnl also can be backed up.
    ;; (assert (cache-path:find lua-cache-prefix 1 true)
    ;;         (-> "expected a path under %s, got %s"
    ;;             (: :format lua-cache-prefix cache-path)))
    (fs.symlink! cache-path link-path)))

(fn BackupHandler.clear-latest-cache! [self]
  "Clear the cache for `module-name` in order to make sure that the `mounted`
backup will be loaded on the next attempt."
  (let [link-path (self:determine-latest-cache-link-path)
        cache-path (fs.readlink link-path)]
    (when (and (= 1 (cache-path:find lua-cache-prefix 1 true))
               (fs.stat cache-path))
      (assert (fs.unlink cache-path)))))

(fn BackupHandler.determine-active-backup-path [self]
  "Return the active backup path for `module-name`.
@return string? the active backup path, or nil if not found"
  (let [backup-dir (self:determine-backup-dir)
        filename self._active-backup-filename]
    (Path.join backup-dir filename)))

(fn BackupHandler.determine-active-backup-birthtime [self]
  "Return the active backup creation time for `module-name`.
@return string? the birthtime of the active backup, or nil if not found"
  (case (-?> (self:determine-active-backup-path self._module-name)
             (fs.stat)
             (. :birthtime :sec))
    time (os.date "%c" time)))

(fn BackupHandler.switch-active-backup! [self path]
  "Switch active backup for `module-name` to `path`.
@param path string"
  (let [dir (self:determine-backup-dir)
        active-backup-path (self:determine-active-backup-path)]
    (assert (path:find dir 1 true)
            (-> "expected path under backup directory %s, got %s"
                (: :format dir path)))
    (fs.symlink! path active-backup-path)))

(fn BackupHandler.determine-mounted-backup-path [self]
  "Return the mounted backup path for `module-name`.
Note that mounted backup is linked to an active backup so that the contents are
always the same.
@return string? the mounted backup path, or nil if not found"
  (let [backup-dir (self:determine-backup-dir)
        filename self._mounted-backup-filename]
    (Path.join backup-dir filename)))

(fn BackupHandler.should-update-backup? [self expected-contents]
  "Check if the backup of the module should be updated.
Return `true` if the following conditions are met:

- `expected-contents` is different from the backed-up contents for the
  module.

@param expected-contents string contents expected for the module
@return boolean true if module should be backed up, false otherwise"
  (let [module-name self._module-name]
    (assert (not (file-readable? module-name))
            (.. "expected module-name, got path " module-name))
    (let [backup-path (self:determine-active-backup-path module-name)]
      (or (not (file-readable? backup-path))
          (not= (read-file backup-path)
                (assert expected-contents
                        "expected non empty string for `expected-contents`"))))))

(fn BackupHandler.has-mounted? [self]
  "Tell if a backup for `module-name` has been mounted.
@return boolean"
  (let [mounted-backup-path (self:determine-mounted-backup-path)]
    (file-readable? mounted-backup-path)))

(fn BackupHandler.mount-backup! [self]
  "Mount currently active backup for `module-name`.
@return boolean true if module has been successfully mounted, false otherwise."
  (let [active-backup-path (self:determine-active-backup-path)
        mounted-backup-path (self:determine-mounted-backup-path)]
    (assert-is-file-readable active-backup-path)
    (fs.symlink! active-backup-path mounted-backup-path)
    ;; esp. for package.loaders.
    (self:clear-latest-cache!)))

(fn BackupHandler.unmount-backup! [self]
  "Unmount previously mounted backup for `module-name`.
@return boolean true if module has been successfully unmounted, false otherwise."
  (let [mounted-backup-path (self:determine-mounted-backup-path)]
    (assert-is-symlink mounted-backup-path)
    (assert (fs.unlink mounted-backup-path))))

(fn BackupHandler.cleanup-old-backups! [self]
  "Remove old backups more than the value of `max-rollbacks` option.
@param module-name string"
  (let [Config (require :thyme.config)
        max-rollbacks Config.max-rollbacks]
    (validate-type :number max-rollbacks)
    (let [threshold (inc max-rollbacks)
          backup-files (self:list-backup-files)]
      (table.sort backup-files sorter/files-to-oldest-by-birthtime)
      (for [i threshold (length backup-files)]
        (let [path (. backup-files i)]
          (assert (fs.unlink path)))))))

(fn BackupHandler.write-backup! [self path]
  "Create a backup file of `path` as `module-name`.
@param path string"
  ;; NOTE: Saving a chunk of macro module is probably impossible.
  (assert (file-readable? path) (.. "expected readable file, got " path))
  (let [module-name self._module-name
        backup-path (self:suggest-new-backup-path module-name)
        active-backup-path (self:determine-active-backup-path module-name)]
    (-> (vim.fs.dirname active-backup-path)
        (vim.fn.mkdir :p))
    (self:update-latest-cache-link! path)
    (assert (fs.copyfile path backup-path))
    (fs.symlink! backup-path active-backup-path)))

BackupHandler
