(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: define-commands!} (require :thyme))

(describe* "integrated with parinfer,"
  (setup (fn []
           (define-commands!)))
  (before_each (fn []
                 (assert.is_truthy (vim.o.rtp:find "parinfer"))))
  (describe* "fnl wrapper commands automatically balance parentheses;"
    (it* "thus, `:Fnl (+ 1 1` results in the same as `:Fnl (+ 1 1)`"
      (assert.equals (vim.fn.execute "Fnl (+ 1 1)")
                     (vim.fn.execute "Fnl (+ 1 1")))))
