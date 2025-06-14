(import-macros {: describe* : it*} :test.helper.busted-macros)

(include "test.helper.prerequisites")

(local Dropin (require :thyme.user.dropin))

(describe* "dropin.register"
  (before_each (fn []
                 (Dropin.registry:clear!)))
  (after_each (fn []
                (Dropin.registry:resume!)))
  (it* "should not replace a valid ex command"
    (Dropin.registry:register! "edit" "bar")
    (let [old-cmdline "edit"]
      (assert.has_no_error #(vim.api.nvim_parse_cmd old-cmdline {}))
      (assert.not_equals "bar"
                         (-> (Dropin.cmdline.replace old-cmdline)
                             (string.match "\"(.-)\"")))
      (assert.equals "edit"
                     (-> (Dropin.cmdline.replace old-cmdline)
                         (string.match "\"(.-)\"")))))
  (it* "should register a dropin function with a given name"
    (Dropin.registry:register! "foo" "bar")
    (let [old-cmdline "foo"]
      (assert.has_error #(vim.api.nvim_parse_cmd old-cmdline {}))
      (assert.equals "bar"
                     (-> (Dropin.cmdline.replace old-cmdline)
                         (string.match "\"(.-)\"")))))
  (it* "should only replace registered pattern"
    (Dropin.registry:register! "foo" "bar")
    (let [old-cmdline "foobar"]
      (assert.has_error #(vim.api.nvim_parse_cmd old-cmdline {}))
      (assert.equals "barbar"
                     (-> (Dropin.cmdline.replace old-cmdline)
                         (string.match "\"(.-)\""))))))
