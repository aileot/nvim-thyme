(import-macros {: when-not} :thyme.macros)

(fn do-nothing []
  "A dummy function to be used as a callback function."
  ;; Note: Return nil, or it will return the docstring.
  nil)

(fn contains? [xs ?a]
  "Check if `?a` is in `xs`.
@param xs sequence
@param a any
@return boolean"
  (faccumulate [eq? false ;
                i 1 (length xs) &until eq?]
    (= ?a (. xs i))))

(fn validate-type [expected val]
  (let [t (type val)]
    (when-not (= t expected)
      (error (.. "expected " expected t)))))

(fn new-matrix [row col val]
  "Create a new metatable to build an two-dimensional array.
@param row number?
@param col number?
@param initial-val any?"
  (let [matrix {}]
    (when col
      (assert row "missing row value")
      (for [i 1 row]
        (rawset matrix i {})
        (for [j 1 col]
          (tset matrix i j val))))
    (setmetatable matrix
      {:__index (fn [self key]
                  (let [tbl {}]
                    (rawset self key tbl)
                    tbl))})))

(fn warn! [raw-msg]
  (let [msg (.. "[thyme] " raw-msg)]
    (vim.notify msg vim.log.levels.WARN)))

{: do-nothing : contains? : validate-type : new-matrix : warn!}
