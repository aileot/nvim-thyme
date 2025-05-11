(import-macros {: when-not : last} :thyme.macros)

(local ModuleMap (require :thyme.dependency.unit))

(local {: uri-encode} (require :thyme.utils.uri))

(local module-maps {})

(λ fnl-path->module-map [fnl-path]
  (or (rawget module-maps fnl-path)
      (let [modmap (ModuleMap.new fnl-path)]
        (when (modmap:logged?)
          (tset module-maps fnl-path modmap))
        modmap)))

(fn log-module-map! [dependency-stackframe dependent-callstack]
  "Log module map.
@param dependency Stackframe
@param dependent-callstack Callstack<Stackframe>"
  ;; NOTE: dependent-stack can be empty when `import-macros` is in cmdline.
  (let [dependency-fnl-path (dependency-stackframe:get-fnl-path)]
    (case (or (. module-maps dependency-fnl-path)
              (let [modmap (ModuleMap.new dependency-fnl-path)]
                (when-not (modmap:logged?)
                  (modmap:initialize-module-map! dependency-stackframe))
                (tset module-maps dependency-fnl-path modmap)
                modmap))
      module-map (case (last dependent-callstack)
                   dependent (when-not (-> (module-map:get-dependent-maps)
                                           (. dependency-fnl-path))
                               (module-map:log-dependent! dependent))))))

(fn fnl-path->entry-map [fnl-path]
  "Get dependency map of `fnl-path`.
@param fnl-path string
@return table"
  ;; NOTE: This function is not intended to be used in this module itself, but
  ;; to be used by other internal modules.
  (-> (fnl-path->module-map fnl-path)
      (: :get-entry-map)))

(fn fnl-path->dependent-map [fnl-path]
  "Get dependent map of `fnl-path`.
@param fnl-path string
@return table"
  ;; NOTE: This function is not intended to be used in this module itself, but
  ;; to be used by other internal modules.
  (-> (fnl-path->module-map fnl-path)
      (: :get-dependent-maps)
      (. fnl-path)))

(fn fnl-path->lua-path [fnl-path]
  "Convert `fnl-path` into the `lua-path`.
@param fnl-path string
@return string? lua path where the compiled result of `fnl-path` should be written."
  (case (fnl-path->entry-map fnl-path)
    modmap modmap.lua-path))

;; (fn lua-path->module-name [lua-path]
;;   (-> (lua-path:sub (+ 2 (length lua-cache-prefix)))
;;       (: :gsub Path.sep ".")))

(fn clear-module-map! [fnl-path]
  "Clear module entry-map of `fnl-path` stored in `module-maps`.
@param fnl-path string"
  (let [modmap (fnl-path->module-map fnl-path)]
    ;; NOTE: Because `log-module-map!` determine to initialize the modmap for
    ;; `fnl-path` by whether `module-maps` stores any table at `fnl-path`,
    ;; escaping the modmap is necessary.
    (tset module-maps (uri-encode fnl-path) modmap)
    (tset module-maps fnl-path nil)))

(fn restore-module-map! [fnl-path]
  "Restore the once-cleared (or hidden) module entry-map of `fnl-path` in
`module-maps`.
@param fnl-path string"
  (let [modmap (fnl-path->module-map (uri-encode fnl-path))]
    (tset module-maps fnl-path modmap)))

{: log-module-map!
 : fnl-path->entry-map
 : fnl-path->dependent-map
 : fnl-path->lua-path
 : clear-module-map!
 : restore-module-map!}
