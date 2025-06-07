(import-macros {: setup* : before-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: vim/normal : vim/normal!} (include :test.helper.util))

(local thyme (require :thyme))
(local Config (require :thyme.config))

;; (describe* "with dropin feature in cmdwin,"
;;   (let [default-dropin-options Config.dropin]
;;     (after_each (fn []
;;                   (set Config.dropin default-dropin-options)))
;;     (describe* "(`<CR>` as the dropin key)"
;;       (before_each (fn []
;;                      (set Config.dropin.cmdwin.enter-key "<CR>")
;;                      (thyme.setup)))
;;       (describe* "`<CR>` should be mapped in cmdwin"
;;         (it* "thus, inputting `:(+ 1 2)<C-f><CR>` should not throw any errors."
;;           ;; NOTE: Either `:execute 'normal! :<C-f>'` or `:normal! q:` do not
;;           ;; open cmdwin.
;;           (vim.api.nvim_input "q:")
;;           ;; TODO: Make sure cursor is on cmdwin in running specs.
;;           (assert.equals "command" (vim.fn.win_gettype)))
;;         (pending #(it* "thus, inputting `:(+ 1 2)<C-f><CR>` should not throw any errors."
;;                     (assert.has_error #(vim/normal! ":(+ 1 2)<C-f><CR>"))
;;                     (assert.has_no_error #(vim/normal ":(+ 1 2)<C-f><CR>"))))))))
