(import-macros {: when-not : last} :thyme.macros)

(local {: state-prefix} (require :thyme.const))

(local Path (require :thyme.util.path))

(local {: file-readable?
        : assert-is-file-readable
        : read-file
        : write-log-file!} (require :thyme.util.fs))

(local {: uri-encode} (require :thyme.util.uri))
(local {: each-file} (require :thyme.util.iterator))

(local {: hide-file! : restore-file! : can-restore-file?}
       (require :thyme.util.pool))

(local HashMap (require :thyme.util.class.hashmap))

(local modmap-prefix (Path.join state-prefix :modmap))

(vim.fn.mkdir modmap-prefix :p)

(local ModuleMap {})
(set ModuleMap.__index ModuleMap)

(fn ModuleMap.new [{: module-name : fnl-path : lua-path}]
  ;; NOTE: fnl-path should be managed in resolved path. Symbolic links are
  ;; unlikely to be either re-set to another file or replaced with a general
  ;; file. Even in such cases, just executing :CacheClear would be the simple
  ;; answer. The symbolic link issue does not belong to dependent-map, but
  ;; only to the entry point, i.e., autocmd's <amatch> and <afile>.
  (assert module-name "expected module-name")
  (assert fnl-path "expected fnl-path")
  (let [self (setmetatable {} ModuleMap)]
    (set self._entry-map {: module-name
                          : fnl-path
                          : lua-path
                          :macro? (= nil lua-path)})
    (set self._dependent-maps {})
    (set self._log-path (ModuleMap.determine-log-path fnl-path))
    (values self)))

(fn ModuleMap.try-read-from-file [raw-fnl-path]
  ;; NOTE: fnl-path should be managed in resolved path. Symbolic links are
  ;; unlikely to be either re-set to another file or replaced with a general
  ;; file. Even in such cases, just executing :CacheClear would be the simple
  ;; answer. The symbolic link issue does not belong to dependent-map, but
  ;; only to the entry point, i.e., autocmd's <amatch> and <afile>.
  (assert-is-file-readable raw-fnl-path)
  (let [self (setmetatable {} ModuleMap)
        id (ModuleMap.fnl-path->path-id raw-fnl-path)
        log-path (ModuleMap.determine-log-path raw-fnl-path)]
    (when (file-readable? log-path)
      (let [encoded (read-file log-path)
            logged-maps (vim.mpack.decode encoded)
            entry-map (. logged-maps id)]
        (set self._entry-map entry-map)
        (tset logged-maps id nil)
        (set self._dependent-maps logged-maps)
        (set self._log-path (ModuleMap.determine-log-path log-path))
        (values self)))))

(fn ModuleMap.get-log-path [self]
  self._log-path)

(fn ModuleMap.get-entry-map [self]
  self._entry-map)

(fn ModuleMap.get-module-name [self]
  (?. self._entry-map :module-name))

(fn ModuleMap.get-fnl-path [self]
  self._entry-map.fnl-path)

(fn ModuleMap.get-lua-path [self]
  self._entry-map.lua-path)

(fn ModuleMap.macro? [self]
  ;; NOTE: It would be more complicated to prepare another dir for macro
  ;; files; log-path could not be determined in "new" method on a simple
  ;; logic.
  (and self._entry-map self._entry-map.macro?))

(fn ModuleMap.get-dependent-maps [self]
  self._dependent-maps)

(fn ModuleMap.write-file! [self]
  "Write module-map to log file.
@return ModuleMap"
  (let [log-path (self:get-log-path)
        entry-map (self:get-entry-map)
        dependent-maps (self:get-dependent-maps)
        entry-id (self.fnl-path->path-id (self:get-fnl-path))
        _ (tset dependent-maps entry-id entry-map)
        encoded (vim.mpack.encode dependent-maps)]
    (tset dependent-maps entry-id nil)
    (if (can-restore-file? log-path encoded)
        (restore-file! log-path)
        (write-log-file! log-path encoded))
    (values self)))

(fn ModuleMap.log-dependent! [self dependent]
  (let [dep-maps (self:get-dependent-maps)
        id (self.fnl-path->path-id dependent.fnl-path)]
    (when-not (. dep-maps id)
      (tset dep-maps id dependent)
      (self:write-file!))))

(fn ModuleMap.clear! [self]
  "Clear dependency map of `dependency-fnl-path`:

- Remove module-map log file.
- Set module-map in memory for `dependency-fnl-path` to `nil`.
  @param dependency-fnl-path string"
  (let [log-path (self:get-log-path)
        dep-map (self:get-dependent-maps)]
    (set self.__entry-map self._entry-map)
    (dep-map:clear!)
    (set self._entry-map nil)
    (hide-file! log-path)))

(fn ModuleMap.restore! [self]
  "Restore once cleared module-map."
  (let [log-path (self:get-log-path)
        dep-map (self:get-dependent-maps)]
    (set self._entry-map self.__entry-map)
    (dep-map:restore!)
    (restore-file! log-path)))

(fn ModuleMap.fnl-path->path-id [raw-fnl-path]
  "Determine `ModuleMap` ID from `raw-fnl-path`.
@param raw-fnl-path string
@return string"
  (assert-is-file-readable raw-fnl-path)
  (vim.fn.resolve raw-fnl-path))

(fn ModuleMap.determine-log-path [raw-path]
  "Convert `path` into `log-path`.
@param path string
@return string"
  (assert-is-file-readable raw-path)
  (let [id (ModuleMap.fnl-path->path-id raw-path)
        log-id (uri-encode id)]
    (Path.join modmap-prefix (.. log-id :.log))))

(fn ModuleMap.has-log? [raw-path]
  "Check if `raw-path` has the corresponding log file on `ModuleMap`.
@param raw-path string
@return boolean"
  (let [log-path (ModuleMap.determine-log-path raw-path)]
    (file-readable? log-path)))

(fn ModuleMap.clear-module-map-files! []
  "Clear all the module-map log files managed by nvim-thyme."
  ;; NOTE: hide-dir! instead also move modmap dir wastefully.
  (each-file hide-file! modmap-prefix))

(fn ModuleMap.get-root []
  "Return the root directory to store module-map states.
  @return string the root path"
  modmap-prefix)

ModuleMap
