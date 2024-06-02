(import-macros {: when-not : last} :thyme.macros)

(local Path (require :thyme.utils.path))
(local ModuleMap (require :thyme.module-map.unit))

(local {: delete-log-file!} (require :thyme.utils.fs))
(local {: each-file} (require :thyme.utils.iterator))
(local {: hide-file!} (require :thyme.utils.pool))
(local {: state-prefix} (require :thyme.const))

(local modmap-prefix (Path.join state-prefix :modmap))

(vim.fn.mkdir modmap-prefix :p)

;; TODO: Replace the metatable on __index with a general function. The
;; metatable is for `get-entry-map` and `get-dependent-map`; never for
;; `log-module-map!`
(local module-maps ;
       (setmetatable {}
         {:__index (fn [self fnl-path]
                     (let [modmap (ModuleMap.new fnl-path)]
                       (tset self fnl-path modmap)
                       modmap))}))

(fn log-module-map! [dependency dependent-stack]
  "Append dependent path to dependency cache file.
@param dependency table
@param dependent-stack table"
  ;; Note: dependent-stack can be empty when `import-macros` is in cmdline.
  (let [module-map (or (rawget module-maps dependency.fnl-path)
                       (let [(modmap logged?) (ModuleMap.new dependency.fnl-path)]
                         (when-not logged?
                           (modmap:set-module-map! dependency))
                         (tset module-maps dependency.fnl-path modmap)
                         modmap))]
    (case (last dependent-stack)
      dependent (when-not (module-map:get-dependent-map dependent.fnl-path)
                  (module-map:add-dependent dependent)))))

(fn fnl-path->entry-map [fnl-path]
  "Get dependency map of `fnl-path`.
@param fnl-path string
@return table"
  ;; Note: This function is not intended to be used in this module itself, but
  ;; to be used by other internal modules.
  (-> (. module-maps fnl-path)
      (: :get-entry-map)))

(fn fnl-path->dependent-map [fnl-path]
  "Get dependent map of `fnl-path`.
@param fnl-path string
@return table"
  ;; Note: This function is not intended to be used in this module itself, but
  ;; to be used by other internal modules.
  (-> (. module-maps fnl-path)
      (: :get-dependent-map)))

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
  "Clear module entry-map of `fnl-path`:
@param fnl-path string"
  (let [modmap (. module-maps fnl-path)]
    (modmap:clear!)))

(fn restore-module-map! [fnl-path]
  "Restore the once-cleared module entry-map of `fnl-path`:
@param fnl-path string"
  (let [modmap (. module-maps fnl-path)]
    (modmap:restore!)))

(fn clear-dependency-log-files! []
  "Clear all the dependency log files managed by nvim-thyme."
  ;; Note: hide-dir! instead also move modmap dir wastefully.
  (each-file hide-file! modmap-prefix))

{: log-module-map!
 : fnl-path->entry-map
 : fnl-path->dependent-map
 : fnl-path->lua-path
 : clear-module-map!
 : restore-module-map!
 : clear-dependency-log-files!}
