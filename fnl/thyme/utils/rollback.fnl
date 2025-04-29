(import-macros {: when-not : inc : first : last} :thyme.macros)

(local Path (require :thyme.utils.path))
(local {: file-readable? : assert-is-file-readable : read-file &as fs}
       (require :thyme.utils.fs))

(local {: state-prefix} (require :thyme.const))

(local {: validate-type : sorter/files-to-oldest-by-birthtime}
       (require :thyme.utils.general))

(local {: hide-file! : has-hidden-file? : restore-file!}
       (require :thyme.utils.pool))

(local RollbackManager
       {:_root (Path.join state-prefix :rollbacks)
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
  (let [dir (Path.join self._labeled-root module-name)]
    dir))

(fn RollbackManager.module-name->backup-files [self module-name]
  "Return backup files for the `module-name`. The special files like `.active`
and `.mounted` are ignored.
@param module-name string
@return string[] backup files"
  (let [backup-dir (self:module-name->backup-dir module-name)]
    (-> (Path.join backup-dir "*")
        (vim.fn.glob false true))))

(fn RollbackManager.module-name->new-backup-path [self module-name]
  "Return module new backed up path for `module-name`.
@param module-name string
@return string the module backup path"
  (let [rollback-id (-> (os.date "%Y-%m-%d_%H-%M-%S")
                        ;; NOTE: os.date does not interpret `%N` for nanoseconds.
                        (.. "_" (vim.uv.hrtime)))
        backup-filename (.. rollback-id self.file-extension)
        backup-dir (self:module-name->backup-dir module-name)]
    (vim.fn.mkdir backup-dir :p)
    (Path.join backup-dir backup-filename)))

(fn RollbackManager.module-name->active-backup-path [self module-name]
  "Return module the active backed up path.
@param module-name string
@return string? the module backup path, or nil if not found"
  (let [backup-dir (self:module-name->backup-dir module-name)
        filename RollbackManager._active-backup-filename]
    (Path.join backup-dir filename)))

(fn RollbackManager.module-name->mounted-backup-path [self module-name]
  "Return module the mounted backed up path.
@param module-name string
@return string? the module backup path, or nil if not found"
  (let [backup-dir (self:module-name->backup-dir module-name)
        filename RollbackManager._mounted-backup-filename]
    (Path.join backup-dir filename)))

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

(fn RollbackManager.cleanup-old-backups! [self module-name]
  "Remove old backups more than the value of `max-rollbacks` option.
@param module-name string"
  (let [{: get-config} (require :thyme.config)
        config (get-config)
        max-rollbacks config.max-rollbacks]
    (validate-type :number max-rollbacks)
    (let [threshold (inc max-rollbacks)
          backup-files (self:module-name->backup-files module-name)]
      (table.sort backup-files sorter/files-to-oldest-by-birthtime)
      (for [i threshold (length backup-files)]
        (let [path (. backup-files i)]
          (assert (fs.unlink path)))))))

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
  (let [loader-path-for-mounted-backups (Path.join self._labeled-root "?"
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
  (let [rollback-path (self:module-name->mounted-backup-path module-name)
        loader-name (-> "thyme-mounted-rollback-%s-loader"
                        (: :format self._label))]
    (if (file-readable? rollback-path)
        (let [resolved-path (fs.readlink rollback-path)
              unmount-arg (Path.join self._label module-name)
              msg (-> "%s: rollback to mounted backup for %s %s
Note that this loader is intended to help you fix the module reducing its annoying errors.
Please execute `:ThymeRollbackUnmount %s`, or `:ThymeRollbackUnmountAll`, to load your runtime %s on &rtp."
                      (: :format loader-name self._label module-name unmount-arg
                         module-name))]
          (vim.notify_once msg vim.log.levels.WARN)
          ;; TODO: Is it redundant to resolve path for error message?
          (loadfile resolved-path))
        (let [error-msg (-> "%s: no mounted backup is found for %s %s"
                            (: :format loader-name self._label module-name))]
          (if (= self._label "macro")
              ;; TODO: Better implementation independent of `self._label`.
              (values nil error-msg)
              error-msg)))))

(fn RollbackManager.inject-mounted-backup-searcher! [self searchers]
  "Inject mounted backup searcher into `searchers` in the highest priority.
@param searchers function[]"
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
        (table.insert searchers 1 self._injected-searcher))
      (not= (first searchers) self._injected-searcher)
      (do
        (faccumulate [dropped? false i 1 (length searchers) &until dropped?]
          (if (= (. searchers i) self._injected-searcher)
              (table.remove searchers i)
              false))
        (table.insert searchers 1 self._injected-searcher))))

;;; Static Methods

(λ RollbackManager.new [label file-extension]
  (let [self (setmetatable {} RollbackManager)
        root (Path.join RollbackManager._root label)]
    (vim.fn.mkdir root :p)
    (set self._label label)
    (set self._labeled-root root)
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
        mounted-backup-path (Path.join backup-dir
                                       RollbackManager._mounted-backup-filename)]
    (symlink! active-backup-path mounted-backup-path)))

(fn RollbackManager.unmount-backup! [backup-dir]
  "Unmount previously mounted backup for `backup-dir`.
@param backup-dir string"
  (let [mounted-backup-path (Path.join backup-dir
                                       RollbackManager._mounted-backup-filename)]
    (assert-is-file-readable mounted-backup-path)
    (assert (fs.unlink mounted-backup-path))))

(fn RollbackManager.get-mounted-rollbacks []
  "Return all the mounted rollbacks.
@return string[] the list of mounted rollbacks"
  (-> (Path.join RollbackManager._root ;
                 "*" ; for rollback label
                 "*" ; for module
                 RollbackManager._mounted-backup-filename)
      (vim.fn.glob false true)))

(fn RollbackManager.unmount-backup-all! []
  "Unmount all the mounted backups.
@return boolean true if all the mounted backups are successfully unmounted, or no backup has been mounted; false otherwise"
  (case (RollbackManager.get-mounted-rollbacks)
    mounted-backup-paths (each [_ path (ipairs mounted-backup-paths)]
                           (assert (fs.unlink path))))
  true)

RollbackManager
