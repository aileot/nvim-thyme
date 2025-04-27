;; fennel-ls: macro-file

(fn when-not [cond ...]
  `(when (not ,cond)
     ,...))

(fn num? [x]
  `(= :number (type ,x)))

(fn str? [x]
  `(= :string (type ,x)))

(fn tbl? [x]
  `(= :table (type ,x)))

(fn inc [x]
  `(+ ,x 1))

(fn dec [x]
  `(- ,x 1))

(fn first [xs]
  `(. ,xs 1))

(fn second [xs]
  `(. ,xs 2))

(fn last [xs]
  `(. ,xs (length ,xs)))

(fn require-with-key [module-name key]
  `(-> (require ,module-name) (. ,key)))

(fn lazy-require-with-key [module-name key]
  `(fn [...]
     (,(require-with-key module-name key) ...)))

(fn error-fmt [text ...]
  `(error (: ,text :format ,...)))

(fn nvim [name ...]
  "Generate `(vim.api.nvim_foobar ...)`."
  ;; NOTE: Define dedicated wrapper macros for arbitrarily nilable params.
  (let [snake-cased (name:gsub "%-" "_")]
    `((. vim.api ,(.. :nvim_ snake-cased)) ,...)))

(fn nvim-set-option [name value ?opts]
  (let [opts (or ?opts {})]
    `(vim.api.nvim_set_option_value ,name ,value ,opts)))

(fn nvim-get-option [name ?opts]
  (let [opts (or ?opts {})]
    `(vim.api.nvim_get_option_value ,name ,opts)))

{: when-not
 : num?
 : str?
 : tbl?
 : inc
 : dec
 : first
 : second
 : last
 : require-with-key
 : lazy-require-with-key
 : error-fmt
 : nvim
 : nvim-set-option
 : nvim-get-option}
