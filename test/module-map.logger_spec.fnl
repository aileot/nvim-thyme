(import-macros {: setup* : after-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))
(local {: fnl-path->lua-path} (require :thyme.module-map.logger))

(local default-fnl-dir (-> (vim.fn.stdpath :config)
                           (vim.fs.joinpath :fnl)))

(describe* "module-map.logger"
  (setup* (fn []
            (thyme.setup)))
  (after-each (fn []
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
                       (-> (fnl-path->lua-path fnl-path)
                           (vim.fn.fnamemodify ":t")))
        (vim.fn.delete fnl-path)))))
