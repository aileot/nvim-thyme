(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))
(local DependencyLogger (require :thyme.dependency.logger))

(local default-fnl-dir (-> (vim.fn.stdpath :config)
                           (vim.fs.joinpath :fnl)))

(describe* "module-map.logger"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (vim.cmd "ThymeUninstall")
                (vim.cmd "% bdelete")))
  (describe* "fnl-path->lua-path"
    (it* "finds the compiled lua file for fnl-path under .config/fnl/ loaded by thyme"
      (-> default-fnl-dir
          (vim.fn.mkdir :p))
      (let [fnl-path (vim.fs.joinpath default-fnl-dir :foo.fnl)]
        (vim.cmd.write fnl-path)
        (require :foo)
        (assert.equals "foo.lua"
                       (-> (DependencyLogger:fnl-path->lua-path fnl-path)
                           (vim.fn.fnamemodify ":t")))
        (vim.fn.delete fnl-path)))))
