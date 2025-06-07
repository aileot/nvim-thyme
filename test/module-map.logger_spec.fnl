(import-macros {: describe* : it*} :test.helper.busted-macros)

(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.util))

(local thyme (require :thyme))
(local DependencyLogger (require :thyme.dependency.logger))

(describe* "module-map.logger"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "fnl-path->lua-path"
    (it* "finds the compiled lua file for fnl-path under .config/fnl/ loaded by thyme"
      (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{}")]
        (require :foo)
        (set package.loaded.foo nil)
        (assert.equals "foo.lua"
                       (-> (DependencyLogger:fnl-path->lua-path fnl-path)
                           (vim.fn.fnamemodify ":t")))
        (vim.fn.delete fnl-path)))))
