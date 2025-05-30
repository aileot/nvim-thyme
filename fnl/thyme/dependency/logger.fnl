(import-macros {: when-not : last} :thyme.macros)

(local ModuleMap (require :thyme.dependency.unit))

(local {: validate-type} (require :thyme.util.general))
(local {: uri-encode} (require :thyme.util.uri))
(local HashMap (require :thyme.util.class.hashmap))

(local {: validate-stackframe!} (require :thyme.dependency.stackframe))

(local ModuleMapLogger {})

(set ModuleMapLogger.__index ModuleMapLogger)

(local module-maps {})

(fn ModuleMapLogger.log-module-map! [self
                                     dependency-stackframe
                                     dependent-callstack]
  "Log module map.
@param dependency Stackframe
@param dependent-callstack Callstack<Stackframe>"
  ;; NOTE: dependent-stack can be empty when `import-macros` is in cmdline.
  (validate-stackframe! dependency-stackframe)
  (let [dependency-fnl-path (dependency-stackframe:get-fnl-path)
        module-map (case (ModuleMap.try-read-from-file dependency-fnl-path)
                     nil (-> (ModuleMap.new dependency-stackframe)
                             (: :write-file!))
                     map (if (and (map:macro?)
                                  (dependency-stackframe:get-lua-path))
                             (-> (ModuleMap.new dependency-stackframe)
                                 (: :write-file!))
                             (values map)))]
    (self._module-name->fnl-path:insert! dependency-stackframe.module-name
                                         dependency-stackframe.fnl-path)
    (self._fnl-path->module-map:insert! dependency-stackframe.fnl-path
                                        module-map)
    (case (last dependent-callstack)
      dependent-stackframe (module-map:log-dependent! dependent-stackframe))))

(fn ModuleMapLogger.fnl-path->module-map [self raw-fnl-path]
  ;; TODO: Save access time to compare
  (or (self._fnl-path->module-map:get raw-fnl-path)
      (case (ModuleMap.try-read-from-file raw-fnl-path)
        modmap (do
                 (self._fnl-path->module-map:insert! raw-fnl-path modmap)
                 (values modmap)))))

(fn ModuleMapLogger.module-name->fnl-path [self module-name]
  (validate-type :string module-name)
  (self._module-name->fnl-path:get module-name))

(fn ModuleMapLogger.fnl-path->module-name [self raw-fnl-path]
  ;; This method can be called before logging in an nvim runtime.
  (-?> (self:fnl-path->module-map raw-fnl-path)
       (: :get-module-name)))

(fn ModuleMapLogger.module-name->module-map [self module-name]
  (case (self:module-name->fnl-path module-name)
    fnl-path (self._fnl-path->module-map:get fnl-path)))

(fn ModuleMapLogger.fnl-path->dependent-maps [self fnl-path]
  "Get dependent maps of `fnl-path`.
@param fnl-path string
@return table"
  ;; NOTE: This function is not intended to be used in this module itself, but
  ;; to be used by other internal modules.
  (-> (self:fnl-path->module-map fnl-path)
      (: :get-dependent-maps)))

(fn ModuleMapLogger.fnl-path->lua-path [self fnl-path]
  "Convert `fnl-path` into the `lua-path`.
@param fnl-path string
@return string? lua path where the compiled result of `fnl-path` should be written."
  (-?> (self:fnl-path->module-map fnl-path)
       (: :get-lua-path)))

;; (fn lua-path->module-name [lua-path]
;;   (-> (lua-path:sub (+ 2 (length lua-cache-prefix)))
;;       (: :gsub Path.sep ".")))

(fn ModuleMapLogger.clear-module-map! [self fnl-path]
  "Clear module entry-map of `fnl-path` stored in `module-maps`.
@param fnl-path string"
  (let [modmap (self:fnl-path->module-map fnl-path)]
    ;; NOTE: Because `log-module-map!` determine to initialize the modmap for
    ;; `fnl-path` by whether `module-maps` stores any table at `fnl-path`,
    ;; escaping the modmap is necessary.
    (tset module-maps (uri-encode fnl-path) modmap)
    (tset module-maps fnl-path nil)))

(fn ModuleMapLogger.restore-module-map! [self fnl-path]
  "Restore the once-cleared (or hidden) module entry-map of `fnl-path` in
`module-maps`.
@param fnl-path string"
  (let [modmap (self:fnl-path->module-map (uri-encode fnl-path))]
    (tset module-maps fnl-path modmap)))

(fn ModuleMapLogger._new []
  "Create a new instance of `ModuleMapLogger`.
@return ModuleMapLogger"
  (let [self (setmetatable {} ModuleMapLogger)]
    (set self._module-name->fnl-path (HashMap.new))
    (set self._fnl-path->module-map (HashMap.new))
    self))

(local SingletonModuleMapLogger (ModuleMapLogger._new))

SingletonModuleMapLogger
