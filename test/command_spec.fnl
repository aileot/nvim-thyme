(import-macros {: after-each : describe* : it*} :test.helper.busted-macros)

(local {: define-commands!} (require :thyme))

(describe* "#command"
  (it* "thyme.define-commands! defines :ThymeCacheClear"
    (define-commands!)
    (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                       (. "must not defined")))
    (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                           (. "ThymeCacheClear")))))
