(import-macros {: setup* : before-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(describe* "thyme.setup"
  (it* "maps `<CR>` on dropin function in Cmdline mode by default"
    (when (not= "" (vim.fn.maparg "<CR>" :c))
      (vim.keymap.del :c "<CR>"))
    (assert.equals "" (vim.fn.maparg "<CR>" :c))
    (thyme.setup)
    (assert.not_equals "" (vim.fn.maparg "<CR>" :c))))

;; WIP: Add tests for dropin with key inputs.
;; (describe* "with dropin feature in cmdline,"
;;   (setup (fn []
;;            (thyme.setup)))
;;   (describe* "`<CR>` should implicitly replace `:(+ 1 2)` with `:Fnl (+ 1 2)`;"
;;     (pending (it* "however, inputting invalid fnl expressions `:(= foo)<CR>` should throw some errors."
;;                (assert.has_error #(vim.api.nvim_input ":(= foo)<CR>"))
;;                (let [keys (vim.keycode ":(= foo)<CR>")]
;;                  (assert.has_error #(vim.api.nvim_feedkeys keys "n" false)))))
;;     (it* "thus, inputting `:(+ 1 2)<CR>` should not throw any errors."
;;       ;; FIXME: This test seems to be meaningless since the tests above does not work.
;;       (assert.has_no_error #(vim.api.nvim_input ":(+ 1 2)<CR>"))
;;       (let [keys (vim.keycode ":(+ 1 2)<CR>")]
;;         (assert.has_no_error #(vim.api.nvim_feedkeys keys "n" false))))))
