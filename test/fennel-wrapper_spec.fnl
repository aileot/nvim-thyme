(import-macros {: describe* : it*} :test.helper.busted-macros)

(require :test.init)

(local fennel (require :fennel))
(local thyme (require :thyme))

(local default-fnl-opts {:correlate false})

(describe* "(fennel wrapper)"
  (describe* :thyme.view
    (describe* "convert `(+ 1 1)`"
      (let [fnl-code "(+ 1 1)"]
        (it* "as the same as `fennel.eval` does."
          (assert.is_same (fennel.view fnl-code default-fnl-opts)
                          (thyme.view fnl-code default-fnl-opts)))
        (it* "into a fennel string."
          (assert.is_same "\"(+ 1 1)\"" (thyme.view fnl-code default-fnl-opts)))
        (it* "into a fennel string with correlate=true."
          (let [fnl-opts {:correlate true}]
            (assert.is_same "\"(+ 1 1)\"" (thyme.view fnl-code fnl-opts)))))))
  (describe* :thyme.eval
    (describe* "evaluates `(+ 1 1)`"
      (let [fnl-code "(+ 1 1)"]
        (it* "as the same as `fennel.eval` does."
          (assert.is_same (fennel.eval fnl-code default-fnl-opts)
                          (thyme.eval fnl-code default-fnl-opts)))
        (it* "result in a number."
          (assert.is_same 2 (thyme.eval fnl-code default-fnl-opts)))
        (it* "result in a number with correlate=true."
          (let [fnl-opts {:correlate true}]
            (assert.is_same 2 (thyme.eval fnl-code fnl-opts)))))))
  ;; TODO: Is thyme.macrodebug theoretically impossible to test?
  ;; /usr/share/lua/5.1/luassert/assertions.lua:126: the 'same' function requires a minimum of 2 arguments, got: 1
  (describe* :thyme.compile-string
    (describe* "compiles `(+ 1 1)`"
      (let [fnl-code "(+ 1 1)"]
        (it* "as the same as `fennel.compile-string` does."
          (assert.is_same (fennel.compile-string fnl-code default-fnl-opts)
                          (thyme.compile-string fnl-code default-fnl-opts)))
        (it* "into lua chunk code."
          (let [fnl-code "(+ 1 1)"]
            (assert.is_same "return (1 + 1)"
                            (thyme.compile-string fnl-code default-fnl-opts))))
        (it* "into lua chunk code with correlate=true."
          (let [fnl-code "(+ 1 1)"
                fnl-opts {:correlate true}]
            (assert.is_same " return (1 + 1)"
                            (thyme.compile-string fnl-code fnl-opts))))))))
