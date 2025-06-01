(import-macros {: when-not : last} :thyme.macros)

(local {: state-prefix} (require :thyme.const))

(local Path (require :thyme.util.path))

(local {: file-readable?
        : assert-is-file-readable
        : assert-is-log-file
        : read-file
        : write-log-file!} (require :thyme.util.fs))

(local {: uri-encode : uri-decode} (require :thyme.util.uri))
(local {: each-file} (require :thyme.util.iterator))

(local {: hide-file! : restore-file! : has-hidden-file? : can-restore-file?}
       (require :thyme.util.pool))

(local modmap-prefix (Path.join state-prefix :modmap))

(vim.fn.mkdir modmap-prefix :p)

(local ModuleMap {})
(set ModuleMap.__index ModuleMap)

(fn ModuleMap.get-root []
  "Return the root directory to store module-map states.
  @return string the root path"
  modmap-prefix)

(fn ModuleMap.clear-module-map-files! []
  "Clear all the module-map log files managed by nvim-thyme."
  ;; NOTE: hide-dir! instead also move modmap dir wastefully.
  (each-file hide-file! modmap-prefix))

(fn ModuleMap.fnl-path->path-id [raw-fnl-path]
  "Determine `ModuleMap` ID from `raw-fnl-path`.
@param raw-fnl-path string
@return string"
  ;; NOTE: fnl-path should be managed in resolved path. Symbolic links are
  ;; unlikely to be either re-set to another file or replaced with a general
  ;; file. Even in such cases, just executing :CacheClear would be the simple
  ;; answer. The symbolic link issue does not belong to dependent-map, but
  ;; only to the entry point, i.e., autocmd's <amatch> and <afile>.
  (assert-is-file-readable raw-fnl-path)
  (vim.fn.resolve raw-fnl-path))

(fn ModuleMap.determine-log-path [raw-path]
  "Convert `path` into `log-path`.
@param path string
@return string"
  (assert-is-file-readable raw-path)
  (assert (not= ".log" (raw-path:sub -4)) ".log file is not allowed")
  (let [id (ModuleMap.fnl-path->path-id raw-path)
        log-id (uri-encode id)]
    (Path.join modmap-prefix (.. log-id :.log))))

(fn ModuleMap.log-path->path-id [log-path]
  "Convert `log-path` into `path-id`.
@param log-path string
@return string"
  (assert-is-log-file log-path)
  (let [decoded (uri-decode log-path)
        path-id (-> decoded
                    (: :match "^(.+)%.log$")
                    (assert (-> "log-path must end with .log, got %s"
                                (: :format log-path)))
                    (: :match (.. "^" modmap-prefix "/(.+)$"))
                    (assert (-> "log-path must start with %s, got %s"
                                (: :format modmap-prefix log-path))))]
    path-id))

(fn ModuleMap.new [{: module-name : fnl-path : lua-path}]
  "Create a new instance of `ModuleMap`.
@param tbl.module-name string
@param tbl.fnl-path string
@param tbl.lua-path string
@return ModuleMap"
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

(fn ModuleMap.decode [encoded path-id]
  "The counterpart of `ModuleMap.encode`.
@return ModuleMap"
  ;; TODO: On v2.0.0, remove the redundnant `path-id` parameter, separating
  ;; entry-map.
  (let [logged-maps (vim.mpack.decode encoded)
        entry-map (. logged-maps path-id)
        self (ModuleMap.new {:module-name entry-map.module-name
                             :fnl-path entry-map.fnl-path
                             :lua-path entry-map.lua-path})]
    (tset logged-maps path-id nil)
    (set self._dependent-maps (if (= logged-maps (vim.empty_dict))
                                  {}
                                  logged-maps))
    (values self)))

(fn ModuleMap.try-read-from-file [raw-fnl-path]
  "Try to restore `ModuleMap` from file.
@param raw-fnl-path string
@return ModuleMap|nil `nil` if the corresponding log file is not found"
  (assert-is-file-readable raw-fnl-path)
  (let [log-path (ModuleMap.determine-log-path raw-fnl-path)]
    (when (file-readable? log-path)
      (let [encoded (read-file log-path)
            path-id (ModuleMap.fnl-path->path-id raw-fnl-path)]
        (ModuleMap.decode encoded path-id)))))

(fn ModuleMap.read-from-log-file [log-path]
  "Read `module-map` from log file.
@param log-path string
@return ModuleMap"
  (assert-is-file-readable log-path)
  (assert-is-log-file log-path)
  (let [path-id (ModuleMap.log-path->path-id log-path)]
    (ModuleMap.try-read-from-file path-id)))

(fn ModuleMap.encode [self]
  "Encode `ModuleMap` to a table ready to save to file.
@return string encoded table of entry-map and dependent-maps in string"
  (let [entry-map (self:get-entry-map)
        dependent-maps (self:get-dependent-maps)
        entry-id (self.fnl-path->path-id (self:get-fnl-path))
        ;; Temporarily set entry-map to dependent-maps.
        ;; TODO: Separate entry-map from dependent-maps, and stop the tweaks
        ;; merging entry-map to dependent-maps on v2.0.0?
        _ (tset dependent-maps entry-id entry-map)
        encoded (vim.mpack.encode dependent-maps)]
    ;; Reset to the previous pure dependent-maps.
    (tset dependent-maps entry-id nil)
    (values encoded)))

(fn ModuleMap.get-log-path [self]
  self._log-path)

(fn ModuleMap.get-entry-map [self]
  self._entry-map)

(fn ModuleMap.get-module-name [self]
  (-> (self:get-entry-map)
      (. :module-name)))

(fn ModuleMap.get-fnl-path [self]
  (-> (self:get-entry-map)
      (. :fnl-path)))

(fn ModuleMap.get-lua-path [self]
  (-> (self:get-entry-map)
      (. :lua-path)))

(fn ModuleMap.macro? [self]
  ;; NOTE: It would be more complicated to prepare another dir for macro
  ;; files; log-path could not be determined in "new" method on a simple
  ;; logic.
  self._entry-map.macro?)

(fn ModuleMap.get-dependent-maps [self]
  self._dependent-maps)

(fn ModuleMap.write-file! [self]
  "Write module-map to log file.
@return ModuleMap"
  (let [log-path (self:get-log-path)
        encoded (self:encode)]
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

(fn ModuleMap.hide! [self]
  "Clear dependency map of `dependency-fnl-path`:

- Remove module-map log file.
- Set module-map in memory for `dependency-fnl-path` to `nil`.
  @param dependency-fnl-path string"
  (let [lua-path (self:get-lua-path)
        log-path (self:get-log-path)]
    (set self.__entry-map self._entry-map)
    (set self.__dependent-maps self._dependent-maps)
    (set self._dependent-maps nil)
    (set self._entry-map nil)
    (when (file-readable? lua-path)
      (hide-file! lua-path))
    (when (file-readable? log-path)
      (hide-file! log-path))))

(fn ModuleMap.restorable? [self]
  "Check if `.restore!` is available.
@return boolean"
  self.__entry-map)

(fn ModuleMap.restore! [self]
  "Restore once cleared module-map."
  (let [lua-path (self:get-lua-path)
        log-path (self:get-log-path)]
    (when self.__entry-map
      (set self._entry-map self.__entry-map)
      (set self._dependent-maps self.__dependent-maps)
      (set self.__dependent-maps nil)
      (set self.__entry-map nil))
    (when (has-hidden-file? lua-path)
      (restore-file! lua-path))
    (when (has-hidden-file? log-path)
      (restore-file! log-path))))

ModuleMap
