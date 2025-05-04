(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(local {: get-config} (require :thyme.config))

(local config (get-config))

(describe* "setup"
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
                               (. :Fnl))))
      (describe* "with arbitrary prefix"
        (it* "e.g., with prefix `Foobar`, it defines `:FoobarEval`"
          (let [last-fnl-cmd-prefix config.command.fnl-cmd-prefix]
            (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                               (. :FoobarEval)))
            (set config.command.fnl-cmd-prefix "Foobar")
            (thyme.setup)
            (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                                   (. :FoobarEval)))
            (set config.command.fnl-cmd-prefix last-fnl-cmd-prefix)
            (thyme.setup)
            (let [commands (vim.api.nvim_get_commands {:builtin false})]
              (each [name _map (pairs commands)]
                (when (vim.startswith name "Foobar")
                  (vim.api.nvim_del_user_command name))))
            (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                               (. :FoobarEval)))))))))
