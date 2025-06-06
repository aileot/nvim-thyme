(import-macros {: setup* : before-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))
(local Config (require :thyme.config))
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
      (assert.not_equals "bar" (Dropin.cmdline.replace old-cmdline))
      (assert.equals "edit" (Dropin.cmdline.replace old-cmdline))))
  (it* "should register a dropin function with a given name"
    (Dropin.registry:register! "foo" "bar")
    (let [old-cmdline "foo"]
      (assert.has_error #(vim.api.nvim_parse_cmd old-cmdline {}))
      (assert.equals "bar" (Dropin.cmdline.replace old-cmdline))))
  (it* "should only replace registered pattern"
    (Dropin.registry:register! "foo" "bar")
    (let [old-cmdline "foobar"]
      (assert.has_error #(vim.api.nvim_parse_cmd old-cmdline {}))
      (assert.equals "barbar" (Dropin.cmdline.replace old-cmdline)))))

;; TODO: Comment out once dropin feature is more stable a bit.
(describe* "thyme.setup enables dropin features"
  (let [default-dropin-options Config.dropin-paren]
    (before_each (fn []
                   (set Config.dropin-paren.cmdline-key "<CR>")
                   (thyme.setup)))
    (after_each (fn []
                  (set Config.dropin-paren default-dropin-options)))
    (it* "maps `<CR>` on dropin function in Cmdline mode by default"
      (when (not= "" (vim.fn.maparg "<CR>" :c))
        (vim.keymap.del :c "<CR>"))
      (assert.equals "" (vim.fn.maparg "<CR>" :c))
      (thyme.setup)
      (assert.not_equals "" (vim.fn.maparg "<CR>" :c)))))

(describe* "with dropin feature in cmdline,"
  (describe* "(`@` as the dropin key)"
    (let [default-dropin-options Config.dropin-paren]
      (before_each (fn []
                     (set Config.dropin-paren.cmdline-key "@")
                     (thyme.setup)
                     (assert.not_equals "" (vim.fn.maparg "@" :c))))
      (after_each (fn []
                    (set Config.dropin-paren default-dropin-options)
                    (vim.api.nvim_del_keymap :c "@"))))
    (describe* "`@` should implicitly replace `:(+ 1 2)` with `:Fnl (+ 1 2)`;"
      ;; FIXME
      ;; (it* "however, inputting invalid fnl expressions `:(= foo)@` should throw some errors."
      ;;   (assert.has_error #(vim.api.nvim_input ":(= foo)@")))
      (it* "thus, inputting `:(+ 1 2)@` should not throw any errors."
        (assert.has_no_error #(vim.api.nvim_input ":(+ 1 2)@"))))))
