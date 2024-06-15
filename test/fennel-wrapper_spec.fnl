(import-macros {: describe* : it*} :test._busted_macros)

(require :test.init)

(local fennel (require :fennel))
(local thyme (require :thyme))

(local default-fnl-opts {:correlate false})

(describe* "fennel wrapper"
  (describe* "apart from &runtimepath"
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
