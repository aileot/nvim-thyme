(import-macros {: describe* : it*} :test.helper.busted-macros)

(include "test.helper.prerequisites")

(describe* "thyme.call.cache.clear"
  (it* "can be called without error."
    (assert.has_no_error #(require "thyme.call.cache.clear"))))

(describe* "thyme.call.setup"
  (it* "can be called without error."
    (assert.has_no_error #(require "thyme.call.setup"))))

(describe* "Invalid tie-in thyme.call interfaces"
  (describe* "whose wrapping function require some arguments"
    (describe* "like thyme.call.loader"
      (it* "throws error."
        (assert.has_error #(require "thyme.call.loader"))))
    (describe* "including thyme.call.fennel interfaces"
      (describe* "like thyme.call.fennel.eval"
        (it* "throws error."
          (assert.has_error #(require "thyme.call.fennel.eval")))))))
