(import-macros {: when-not : last} :thyme.macros)

(local {: state-prefix} (require :thyme.const))

(local Path (require :thyme.utils.path))

(local {: file-readable?
        : assert-is-file-readable
        : write-log-file!
        : append-log-file!} (require :thyme.utils.fs))

(local {: uri-encode} (require :thyme.utils.uri))
(local {: each-file} (require :thyme.utils.iterator))

(local {: hide-file! : restore-file! : can-restore-file?}
       (require :thyme.utils.pool))

(local HashMap (require :thyme.utils.hashmap))

(local {: validate-stackframe! &as Stackframe}
       (require :thyme.dependency.stackframe))

(local {: modmap->line : read-module-map-file} (require :thyme.dependency.io))

(local modmap-prefix (Path.join state-prefix :modmap))

(vim.fn.mkdir modmap-prefix :p)

(local ModuleMap {})
(set ModuleMap.__index ModuleMap)

(fn ModuleMap.new [raw-fnl-path]
  ;; NOTE: fnl-path should be managed in resolved path. Symbolic links are
  ;; unlikely to be either re-set to another file or replaced with a general
  ;; file. Even in such cases, just executing :CacheClear would be the simple
  ;; answer. The symbolic link issue does not belong to dependent-map, but
  ;; only to the entry point, i.e., autocmd's <amatch> and <afile>.
  (let [self (setmetatable {} ModuleMap)
        id (ModuleMap.fnl-path->id raw-fnl-path)
        log-path (ModuleMap.determine-log-path id)
        logged? (file-readable? log-path)
        modmap (if logged?
                   (read-module-map-file log-path)
                   {})]
    (set self._log-path log-path)
    (set self._entry-map (. modmap id))
    (tset modmap id nil)
    (set self._dependent-maps (HashMap.new))
    (values self)))

(fn ModuleMap.try-read-from-file [raw-fnl-path]
  ;; NOTE: fnl-path should be managed in resolved path. Symbolic links are
  ;; unlikely to be either re-set to another file or replaced with a general
  ;; file. Even in such cases, just executing :CacheClear would be the simple
  ;; answer. The symbolic link issue does not belong to dependent-map, but
  ;; only to the entry point, i.e., autocmd's <amatch> and <afile>.
  (assert-is-file-readable raw-fnl-path)
  (let [self (setmetatable {} ModuleMap)
        id (ModuleMap.fnl-path->id raw-fnl-path)
        log-path (ModuleMap.determine-log-path id)]
    (when (file-readable? log-path)
      (case (read-module-map-file log-path)
        modmap (do
                 (set self._log-path log-path)
                 (set self._entry-map (. modmap id))
                 (tset modmap id nil)
                 (set self._dep-map modmap)
                 self)))))

(fn ModuleMap.initialize-module-map! [self {: module-name &as modmap}]
  ;; TODO: Re-design ModuleMap method dropping logged? check to
  ;; call initialize-module-map!
  ;; NOTE: fnl-path should be managed in resolved path as described in the
  ;; `new` method.
  (let [modmap-line (modmap->line modmap)
        log-path (self:get-log-path)]
    (assert (not (file-readable? log-path))
            (.. "this method only expects an empty log file for the module "
                module-name))
    (if (can-restore-file? log-path modmap-line)
        (restore-file! log-path)
        (write-log-file! log-path modmap-line))
    (set self._entry-map modmap)))

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

(fn ModuleMap.log-dependent! [self dependent]
  (let [dep-map (self:get-dependent-maps)
        id (self.fnl-path->id dependent.fnl-path)]
    (when-not (dep-map:contains? id)
      (let [modmap-line (modmap->line dependent)
            log-path (self:get-log-path)]
        (dep-map:insert! id dependent)
        (append-log-file! log-path modmap-line)))))

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

(fn ModuleMap.fnl-path->id [raw-fnl-path]
  "Determine `ModuleMap` ID from `raw-fnl-path`.
@param raw-fnl-path string
@return string"
  (vim.fn.resolve raw-fnl-path))

(fn ModuleMap.determine-log-path [raw-path]
  "Convert `path` into `log-path`.
@param path string
@return string"
  (let [id (ModuleMap.fnl-path->id raw-path)
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
