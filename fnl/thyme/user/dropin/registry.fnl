(import-macros {: ++} :thyme.macros)

(local Registry {})

(set Registry.__index Registry)

(fn Registry.new []
  (let [self (setmetatable {} Registry)]
    (set self._registry [])
    self))

(fn Registry.clear! [self]
  (set self._registry []))

(λ Registry.register! [self pattern replacement]
  "Register a pair of `pattern` and `replacement` to dropin.
@param pattern string Lua patterns to be support dropin fallback.
@param replacement string The dropin command"
  (let [unit {: pattern : replacement}]
    (table.insert self._registry unit)))

(fn Registry.iter [self]
  "Iterate pattern-replacement over registry.
@return number
@return any"
  (var i 0)
  (fn []
    (case (. self._registry (++ i))
      val (values i val))))

Registry
