(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(describe* "setup"
  (it* "should be called without arguments"
    (assert.has_no_error #(thyme.setup)))
  (it* "can also be called with an empty table"
    (assert.has_no_error #(thyme.setup {})))
  (it* "should throw errors with non-empty table"
    (assert.has_error #(thyme.setup {:foo :bar}))))
