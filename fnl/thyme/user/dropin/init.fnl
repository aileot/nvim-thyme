(local Config (require :thyme.config))
(local {: debug?} (require :thyme.const))
(local DropinRegistry (require :thyme.user.dropin.registry))
(local DropinCmdline (require :thyme.user.dropin.replacer.cmdline))

(local M {})

(fn map-keys-in-cmdline! []
  (let [opts Config.dropin-paren
        plug-map-insert "<Plug>(thyme-dropin-insert-Fnl)"
        plug-map-complete "<Plug>(thyme-dropin-complete-Fnl)"]
    ;; (vim.api.nvim_set_keymap :c "<C-j>" "<Plug>(thyme-precede-paren-by-Fnl)"
    ;;   {})
    (case opts.cmdline-key
      false nil
      "" nil
      key (do
            (vim.api.nvim_set_keymap :c plug-map-insert
              ;; NOTE: `v:lua` interface does not support method call.
              "<C-BSlash>ev:lua.require('thyme.user.dropin').cmdline.replace(getcmdline())<CR><CR>"
              {:noremap true})
            ;; TODO: Expose `<Plug>` keymaps once stable a bit.
            (vim.api.nvim_set_keymap :c key plug-map-insert {:noremap true})))
    (case opts.cmdline-completion-key
      false nil
      "" nil
      key (do
            (vim.api.nvim_set_keymap :c plug-map-complete
              "<Cmd>lua require('thyme.user.dropin').cmdline.complete(vim.fn.getcmdline())<CR>"
              {:noremap true})
            (vim.api.nvim_set_keymap :c key plug-map-complete {:noremap true})))))

(fn M.enable-dropin-paren! []
  "Realize dropin-paren feature.
The configurations are only modifiable at the `dropin-parens` attributes in `.nvim-thyme.fnl`."
  ;; TODO: Extract dropin feature into another plugin.
  ;; TODO: Merge the dropin options to `command.dropin`?
  ;; TODO: Support cmdwin.
  ;; (each [_ key (ipairs opts.dropin-parens.cmdwin)]
  ;;   (vim.api.nvim_set_keymap :n key "<Plug>(thyme-precede-paren-by-Fnl)"
  ;;     {:noremap true}))
  (map-keys-in-cmdline!))

(let [registry (DropinRegistry.new)]
  (registry:register! "^[[%[%(%{].*" "Fnl %0")
  (set M.registry registry)
  (set M.cmdline {:replace #(if (or (= ":" (vim.fn.getcmdtype)) debug?)
                                (let [dropin (DropinCmdline.new registry)]
                                  (dropin:replace-cmdline! $...))
                                $...)
                  :complete #(if (= ":" (vim.fn.getcmdtype))
                                 (let [dropin (DropinCmdline.new registry)]
                                   (dropin:complete-cmdline! $...))
                                 $...)})
  M)
