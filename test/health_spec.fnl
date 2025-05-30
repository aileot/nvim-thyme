(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))
(local thyme-health (require :thyme.health))

(describe* "health.check"
  (setup (fn []
           (thyme.setup)))
  (it* "can be called without error"
    (assert.has_no_error thyme-health.check)))
