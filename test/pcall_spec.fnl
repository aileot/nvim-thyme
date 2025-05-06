(import-macros {: describe* : it*} :test.helper.busted-macros)

(describe* "thyme.call.cache.clear"
  (it* "can be called without error."
    (assert.has_no_error #(pcall require "thyme.call.cache.clear"))))
