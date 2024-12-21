(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.prerequisites)

(local {: watch-files!} (require :thyme))

(describe* :watch-files!
  (describe* "defines an augroup ThymeWatch"
    (it* "which includes an autocmd on BufWritePost"
      (watch-files!)
      (->> (next (vim.api.nvim_get_autocmds {:group :ThymeWatch
                                             :event :BufWritePost}))
           (assert.is_not_nil)))))
