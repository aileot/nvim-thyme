(import-macros {: when-not : last} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: file-readable? : write-log-file! : append-log-file!}
       (require :thyme.utils.fs))

(local {: uri-encode} (require :thyme.utils.uri))

(local {: state-prefix} (require :thyme.const))

(local {: hide-file! : restore-file!} (require :thyme.utils.pool))

(local {: modmap->line : read-module-map-file}
       (require :thyme.module-map.format))

(local modmap-prefix (Path.join state-prefix :modmap))

(local ModuleMap {})
(set ModuleMap.__index ModuleMap)

(fn fnl-path->log-path [dependency-fnl-path]
  "Convert `dependency-fnl-path` into `log-path`.
@param dependency-fnl-path string
@return string"
  (let [log-id (uri-encode dependency-fnl-path)]
    (Path.join modmap-prefix (.. log-id :.log))))

(fn ModuleMap.new [raw-fnl-path]
  ;; Note: fnl-path should be managed in resolved path. Symbolic links are
  ;; unlikely to be either re-set to another file or replaced with a general
  ;; file. Even in such cases, just executing :CacheClear would be the simple
  ;; answer. The symbolic link issue does not belong to dependent-map, but
  ;; only to the entry point, i.e., autocmd's <amatch> and <afile>.
  (let [self (setmetatable {} ModuleMap)
        fnl-path (vim.fn.resolve raw-fnl-path)
        log-path (fnl-path->log-path fnl-path)
        logged? (file-readable? log-path)
        modmap (if logged?
                   (read-module-map-file log-path)
                   {})]
    (set self._log-path log-path)
    (set self._entry-map (. modmap fnl-path))
    (tset modmap fnl-path nil)
    (set self._dep-map modmap)
    (values self logged?)))

(fn ModuleMap.set-module-map! [self
                               {: module-name
                                : fnl-path
                                :lua-path _lua-path
                                :macro? _macro?
                                &as modmap}]
  ;; Note: fnl-path should be managed in resolved path as described in the
  ;; `new` method.
  (set modmap.fnl-path (vim.fn.resolve fnl-path))
  (let [modmap-line (modmap->line modmap)
        log-path (self:get-log-path)]
    (assert (not (file-readable? log-path))
            (.. "this method only expects an empty log file for the module "
                module-name))
    (write-log-file! log-path modmap-line)
    (set self._entry-map modmap)))

(fn ModuleMap.get-log-path [self]
  self._log-path)

(fn ModuleMap.get-entry-map [self]
  self._entry-map)

(fn ModuleMap.get-module-name [self]
  self._entry-map.module-name)

(fn ModuleMap.get-fnl-path [self]
  self._entry-map.fnl-path)

(fn ModuleMap.get-lua-path [self]
  self._entry-map.lua-path)

(fn ModuleMap.macro? [self]
  self._entry-map.macro?)

(fn ModuleMap.get-dependent-maps [self]
  self._dep-map)

(fn ModuleMap.get-dependent-map [self dependent-fnl-path]
  (. self._dep-map dependent-fnl-path))

(fn ModuleMap.add-dependent [self dependent]
  (when-not (. self._dep-map dependent.fnl-path)
    (let [modmap-line (modmap->line dependent)
          log-path (self:get-log-path)]
      (tset self._dep-map dependent.fnl-path dependent)
      (append-log-file! log-path modmap-line))))

(fn ModuleMap.clear! [self]
  "Clear dependency map of `dependency-fnl-path`:
- Remove module-map log file.
- Set module-map in memory for `dependency-fnl-path` to `nil`.
@param dependency-fnl-path string"
  (let [log-path (self:get-log-path)]
    (set self.__entry-map self._entry-map)
    (set self.__dep-map self._dep-map)
    (set self._entry-map nil)
    (set self._dep-map nil)
    (hide-file! log-path)))

(fn ModuleMap.restore! [self]
  "Restore once cleared module-map."
  (let [log-path (self:get-log-path)]
    (set self._entry-map self.__entry-map)
    (set self._dep-map self.__dep-map)
    (restore-file! log-path)))

ModuleMap
