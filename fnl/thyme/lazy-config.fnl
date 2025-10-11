;; Access config via metatable avoiding unintended loop in loading 'thyme'
;; modules.

(setmetatable {}
  {:__index (fn [_self key]
              ;; NOTE: Because thyme.config itself is also a metatable, the
              ;; results should should not be set at key permanently.
              (. (require :thyme.config) key))})
