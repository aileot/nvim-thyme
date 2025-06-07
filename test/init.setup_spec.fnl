(import-macros {: describe* : it*} :test.helper.busted-macros)

(local thyme (require :thyme))
(local {: remove-context-files!} (include :test.helper.util))

(describe* "setup"
  (after_each (fn []
                (remove-context-files!)))
  (describe* "can be called"
    (it* "without arguments"
      (assert.has_no_error #(thyme.setup)))
    (it* "with an empty table"
      (assert.has_no_error #(thyme.setup {})))
    (it* "in method call syntax"
      (assert.has_no_error #(thyme:setup))
      (assert.has_no_error #(thyme:setup {}))))
  (it* "should throw errors with non-empty table"
    (assert.has_error #(thyme.setup {:foo :bar})))
  (describe* "defines an augroup ThymeWatch"
    (it* "which includes an autocmd on BufWritePost"
      (thyme.setup)
      (->> (next (vim.api.nvim_get_autocmds {:group :ThymeWatch
                                             :event :BufWritePost}))
           (assert.is_not_nil))))
  (describe* "should define commands"
    (before_each (fn []
                   (let [commands (vim.api.nvim_get_commands {:builtin false})]
                     (each [name _map (pairs commands)]
                       (vim.api.nvim_del_user_command name)))))
    (after_each (fn []
                  ;; Since the other specs depends on `thyme.setup`
                  ;; only on `setup`, restore the state.
                  (thyme.setup)))
    (describe* "dedicated to thyme"
      (it* "e.g., :ThymeCacheClear"
        (thyme.setup)
        (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                           (. "must not defined")))
        (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                               (. "ThymeCacheClear")))))
    (describe* "wrapping fennel APIs"
      (it* "e.g., :Fnl"
        (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                           (. :Fnl)))
        (thyme.setup)
        (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                               (. :Fnl)))))))
