(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(describe* "`:checkhealth thyme`"
  (setup (fn []
           (thyme.setup)))
  (it* "opens a healthcheck buffer"
    (vim.cmd "checkhealth thyme")
    (assert.equals :checkhealth vim.bo.filetype)
    (vim.cmd :close)))
