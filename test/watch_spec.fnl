(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.prerequisites)

(local {: watch-files!} (require :thyme))

(describe* :watch-files!
  (describe* "defines an augroup ThymeWatch"
    (it* "which includes an autocmd on BufWritePost"
      (watch-files!)
      (assert.equals 1
                     (length (vim.api.nvim_get_autocmds {:group :ThymeWatch
                                                         :event :BufWritePost}))))))
