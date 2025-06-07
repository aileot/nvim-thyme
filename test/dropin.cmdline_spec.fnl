(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: vim/normal : vim/normal!} (include :test.helper.util))

(local thyme (require :thyme))
(local Config (require :thyme.config))

;; TODO: Comment out once dropin feature is more stable a bit.
(describe* "thyme.setup enables dropin features"
  (let [default-dropin-options Config.dropin]
    (before_each (fn []
                   (set Config.dropin.cmdline-key "<CR>")
                   (thyme.setup)))
    (after_each (fn []
                  (set Config.dropin default-dropin-options)))
    (it* "maps `<CR>` on dropin function in Cmdline mode by default"
      (when (not= "" (vim.fn.maparg "<CR>" :c))
        (vim.keymap.del :c "<CR>"))
      (assert.equals "" (vim.fn.maparg "<CR>" :c))
      (thyme.setup)
      (assert.not_equals "" (vim.fn.maparg "<CR>" :c)))))

(describe* "with dropin feature in cmdline,"
  (let [default-dropin-options Config.dropin]
    (after_each (fn []
                  (set Config.dropin default-dropin-options)))
    (describe* "(`<CR>` as the dropin key)"
      (before_each (fn []
                     (set Config.dropin.cmdline-key "<CR>")
                     (thyme.setup)
                     (assert.not_equals "" (vim.fn.maparg "<CR>" :c))))
      (after_each (fn []
                    (vim.api.nvim_del_keymap :c "<CR>")))
      (describe* "`<CR>` should implicitly replace `:(+ 1 2)` with `:Fnl (+ 1 2)`;"
        ;; FIXME
        ;; (it* "however, inputting invalid fnl expressions `:(= foo)<CR>` should throw some errors."
        ;;   (assert.has_error #(vim.api.nvim_input ":(= foo)<CR>")))
        (it* "thus, inputting `:(+ 1 2)<CR>` should not throw any errors."
          ;; NOTE: `nvim_input` does not throw errors.
          ;; (assert.has_error #(vim.api.nvim_input ":(+ 1 2)<CR>"))
          (assert.has_error #(vim/normal! ":(+ 1 2)<CR>"))
          (assert.has_no_error #(vim.cmd (vim.keycode "normal :(+ 1 2)<CR>"))))))
    (describe* "(`@` as the dropin key)"
      (before_each (fn []
                     (set Config.dropin.cmdline-key "@")
                     (thyme.setup)
                     (assert.not_equals "" (vim.fn.maparg "@" :c))))
      (after_each (fn []
                    (vim.api.nvim_del_keymap :c "@")))
      (describe* "`@` should implicitly replace `:(+ 1 2)` with `:Fnl (+ 1 2)`;"
        ;; FIXME
        ;; (it* "however, inputting invalid fnl expressions `:(= foo)@` should throw some errors."
        ;;   (assert.has_error #(vim.api.nvim_input ":(= foo)@")))
        (it* "thus, inputting `:(+ 1 2)@` should not throw any errors."
          ;; NOTE: `nvim_input` does not throw errors.
          ;; (assert.has_error #(vim.api.nvim_input ":(+ 1 2)<CR>"))
          (assert.has_error #(vim/normal! ":(+ 1 2)<CR>"))
          (assert.has_no_error #(vim/normal ":(+ 1 2)@")))))))

(describe* "with dropin feature in cmdline,"
  (describe* "(`<Tab>` as the dropin completion key)"
    (let [default-dropin-options Config.dropin]
      (before_each (fn []
                     (set Config.dropin.cmdline-completion-key "<Tab>")
                     (thyme.setup)
                     (assert.not_equals "" (vim.fn.maparg "<Tab>" :c))))
      (after_each (fn []
                    (set Config.dropin default-dropin-options)
                    (vim.api.nvim_del_keymap :c "<Tab>"))))
    (describe* "`<Tab>` should trigger completion `:(+ 1 2)` as `:Fnl (+ 1 2)`;"
      (it* "thus, inputting `:(+ 1 2)^` should not throw any errors."
        ;; TODO: Better check to make sure completion on &wildcharm work since invalid
        ;; &wildcharm input does not throw any errors. However, the specs for
        ;; completion-key are only useful to make sure no errors happens due to
        ;; invalid nvim-thyme implementation.
        (assert.has_no_error #(vim.cmd (vim.keycode "normal :(+ 1 2)<Tab>"))))))
  (describe* "(`^` as the dropin completion key)"
    (let [default-dropin-options Config.dropin]
      (before_each (fn []
                     (set Config.dropin.cmdline-completion-key "^")
                     (thyme.setup)
                     (assert.not_equals "" (vim.fn.maparg "^" :c))))
      (after_each (fn []
                    (set Config.dropin default-dropin-options)
                    (vim.api.nvim_del_keymap :c "^"))))
    (describe* "`^` should trigger completion `:(+ 1 2)` as `:Fnl (+ 1 2)`;"
      (it* "thus, inputting `:(+ 1 2)^` should not throw any errors."
        (assert.has_no_error #(vim/normal ":(+ 1 2)^"))))))
