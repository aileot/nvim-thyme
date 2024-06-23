(import-macros {: describe* : it*} :test.helper.busted-macros)

(require :test.context.prerequisites)

(local fennel (require :fennel))
(local thyme (require :thyme))

(describe* "(fennel wrapper)"
  (describe* :thyme.view
    (describe* "converts a fennel expression"
      (describe* "as the same as `fennel.view` does;"
        (describe* "thus, `(thyme.view (+ 1 1) {:correlate false})`"
          (let [fnl-code "(+ 1 1)"]
            (it* "returns as the same as `fennel.eval` does."
              (assert.is_same (fennel.view fnl-code {:correlate false})
                              (thyme.view fnl-code {:correlate false})))
            (it* "returns the string \"(+ 1 1)\"."
              (assert.is_same "\"(+ 1 1)\""
                              (thyme.view fnl-code {:correlate false}))))))))
  (describe* :thyme.eval
    (describe* "evaluates a fennel expression"
      (describe* "as the same as `fennel.view` does;"
        (describe* "thus, `(thyme.eval (+ 1 1) {:correlate false})`"
          (let [fnl-code "(+ 1 1)"]
            (it* "returns as the same as `fennel.eval` does."
              (assert.is_same (fennel.eval fnl-code {:correlate false})
                              (thyme.eval fnl-code {:correlate false})))
            (it* "returns the number `2`."
              (assert.is_same 2 (thyme.eval fnl-code {:correlate false}))))))))
  ;; TODO: Is thyme.macrodebug theoretically impossible to test?
  ;; /usr/share/lua/5.1/luassert/assertions.lua:126: the 'same' function requires a minimum of 2 arguments, got: 1
  (describe* :thyme.compile-string
    (describe* "evaluates a fennel expression"
      (describe* "as the same as `fennel.compile-string` does;"
        (describe* "thus, `(thyme.compile-string (+ 1 1) {:correlate false})`"
          (let [fnl-code "(+ 1 1)"]
            (it* "returns as the same as `fennel.compile-string` does."
              (assert.is_same (fennel.compile-string fnl-code
                                                     {:correlate false})
                              (thyme.compile-string fnl-code {:correlate false})))
            (it* "returns the string of the lua chunk code \"return (1 + 1)\"."
              (let [fnl-code "(+ 1 1)"]
                (assert.is_same "return (1 + 1)"
                                (thyme.compile-string fnl-code
                                                      {:correlate false}))))))))))
