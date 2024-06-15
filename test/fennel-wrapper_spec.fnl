(import-macros {: describe* : it*} :test._busted_macros)

(require :test.init)

(local fennel (require :fennel))
(local thyme (require :thyme))

(local default-fnl-opts {:correlate false})

(describe* "fennel wrapper"
  (describe* "apart from &runtimepath"
    (describe* :.view
      (describe* "compiles fennel code into lua code"
        (it* "as the same as `fennel.eval` does."
          (let [fnl-code "(+ 1 1)"]
            (assert.is_same (fennel.view fnl-code default-fnl-opts)
                            (thyme.view fnl-code default-fnl-opts))))
        (it* "compiles fennel code into lua chunk code."
          (let [fnl-code "(+ 1 1)"]
            (assert.is_same "\"(+ 1 1)\""
                            (thyme.view fnl-code default-fnl-opts))))
        (it* "compiles fennel code into lua chunk code with correlate option."
          (let [fnl-code "(+ 1 1)"
                fnl-opts {:correlate true}]
            (assert.is_same "\"(+ 1 1)\"" (thyme.view fnl-code fnl-opts))))))
    (describe* :.eval
      (describe* "compiles fennel code into lua code"
        (it* "as the same as `fennel.eval` does."
          (let [fnl-code "(+ 1 1)"]
            (assert.is_same (fennel.eval fnl-code default-fnl-opts)
                            (thyme.eval fnl-code default-fnl-opts))))
        (it* "compiles fennel code into lua chunk code."
          (let [fnl-code "(+ 1 1)"]
            (assert.is_same 2 (thyme.eval fnl-code default-fnl-opts))))
        (it* "compiles fennel code into lua chunk code with correlate option."
          (let [fnl-code "(+ 1 1)"
                fnl-opts {:correlate true}]
            (assert.is_same 2 (thyme.eval fnl-code fnl-opts))))))
    (describe* :.compile-string
      (describe* "compiles fennel code into lua code"
        (it* "as the same as `fennel.compile-string` does."
          (let [fnl-code "(+ 1 1)"]
            (assert.is_same (fennel.compile-string fnl-code default-fnl-opts)
                            (thyme.compile-string fnl-code default-fnl-opts))))
        (it* "compiles fennel code into lua chunk code."
          (let [fnl-code "(+ 1 1)"]
            (assert.is_same "return (1 + 1)"
                            (thyme.compile-string fnl-code default-fnl-opts))))
        (it* "compiles fennel code into lua chunk code with correlate option."
          (let [fnl-code "(+ 1 1)"
                fnl-opts {:correlate true}]
            (assert.is_same " return (1 + 1)"
                            (thyme.compile-string fnl-code fnl-opts))))))))
