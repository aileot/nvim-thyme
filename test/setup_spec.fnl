(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(describe* "setup"
  (it* "can be called without arguments"
    (assert.has_no_error #(thyme.setup)))
  (it* "can also be called with an empty table"
    (assert.has_no_error #(thyme.setup {})))
  (it* "can also be called in method call syntax"
    (assert.has_no_error #(thyme:setup))
    (assert.has_no_error #(thyme:setup {})))
  (it* "should throw errors with non-empty table"
    (assert.has_error #(thyme.setup {:foo :bar})))
  (describe* "defines an augroup ThymeWatch"
    (it* "which includes an autocmd on BufWritePost"
      (thyme.setup)
      (->> (next (vim.api.nvim_get_autocmds {:group :ThymeWatch
                                             :event :BufWritePost}))
           (assert.is_not_nil)))))
