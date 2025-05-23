(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(include :test.helper.assertions)

(local thyme (require :thyme))

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
                                  "<Plug>(thyme-operator-print-compile-string)")))))
