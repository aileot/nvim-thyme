(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: config-filename} (require :thyme.const))

(it* "The config file name is .nvim-thyme.fnl"
  (assert.is_same ".nvim-thyme.fnl" config-filename))
