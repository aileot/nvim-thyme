(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(describe* "`:checkhealth thyme`"
  (setup (fn []
           (thyme.setup)))
  (it* "opens a healthcheck buffer"
    (vim.cmd "checkhealth thyme")
    ;; NOTE: Since nvim 0.12, `:checkhealth` runs checks asynchronously in a
    ;; child process, so wait until the buffer gets its filetype.
    (vim.wait 5000 (fn [] (= :checkhealth vim.bo.filetype)))
    (assert.equals :checkhealth vim.bo.filetype)
    (vim.cmd :close)))
