(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.assertions)

(local thyme (require :thyme))

(local Config (require :thyme.config))

(describe* "keymap feature"
  (setup (fn []
           (thyme.setup)))
  (describe* "should support <Plug> prefixed operator mappings"
    (it* "both on Normal mode and Visual mode"
      (let [modes ["n" "x"]]
        (each [_ m (ipairs modes)]
          (assert.is.key-mapped m "<Plug>(thyme-operator-echo-eval)")
          (assert.is.key-mapped m "<Plug>(thyme-operator-echo-eval-compiler)")
          (assert.is.key-mapped m "<Plug>(thyme-operator-echo-macrodebug)")
          (assert.is.key-mapped m "<Plug>(thyme-operator-echo-compile-string)")
          (assert.is.key-mapped m "<Plug>(thyme-operator-print-eval)")
          (assert.is.key-mapped m "<Plug>(thyme-operator-print-eval-compiler)")
          (assert.is.key-mapped m "<Plug>(thyme-operator-print-macrodebug)")
          (assert.is.key-mapped m "<Plug>(thyme-operator-print-compile-string)"))))
    (it* "not on Select mode"
      (let [m "s"]
        (assert.is_not.key-mapped m "<Plug>(thyme-operator-echo-eval)")
        (assert.is_not.key-mapped m "<Plug>(thyme-operator-echo-eval-compiler)")
        (assert.is_not.key-mapped m "<Plug>(thyme-operator-echo-macrodebug)")
        (assert.is_not.key-mapped m
                                  "<Plug>(thyme-operator-echo-compile-string)")
        (assert.is_not.key-mapped m "<Plug>(thyme-operator-print-eval)")
        (assert.is_not.key-mapped m
                                  "<Plug>(thyme-operator-print-eval-compiler)")
        (assert.is_not.key-mapped m "<Plug>(thyme-operator-print-macrodebug)")
        (assert.is_not.key-mapped m
                                  "<Plug>(thyme-operator-print-compile-string)"))))
  (describe* "should map key on `<Plug>(thyme-operator-echo-eval)`"
    (let [lhs "foo"]
      (before_each (fn []
                     (set Config.keymap.mappings
                          {[:n :x] {:operator-echo-eval lhs}})
                     (thyme.setup)))
      (it* "when filetype is fennel"
        (vim.cmd :new)
        (set vim.bo.filetype "fennel")
        (let [modes ["n" "x"]]
          (each [_ m (ipairs modes)]
            (assert.is_same "<Plug>(thyme-operator-echo-eval)"
                            (vim.fn.maparg lhs m))))
        (vim.cmd :bdelete))
      (it* "should not map key on `<Plug>(thyme-operator-echo-eval)` other than in fennel"
        (vim.cmd :new)
        (set vim.bo.filetype "lua")
        (let [modes ["n" "x"]]
          (each [_ m (ipairs modes)]
            (assert.is_not_same "<Plug>(thyme-operator-echo-eval)"
                                (vim.fn.maparg lhs m))))))))
