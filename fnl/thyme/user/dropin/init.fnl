(local Config (require :thyme.config))
(local {: debug?} (require :thyme.const))
(local DropinRegistry (require :thyme.user.dropin.registry))
(local DropinCmdline (require :thyme.user.dropin.replacer.cmdline))

(local M {})

(fn map-keys-in-cmdline! []
  (let [opts Config.dropin
        plug-map-insert "<Plug>(thyme-dropin-insert-Fnl-if-needed)"
        plug-map-complete "<Plug>(thyme-dropin-complete-with-Fnl-if-needed)"]
    ;; (vim.api.nvim_set_keymap :c "<C-j>" "<Plug>(thyme-precede-paren-by-Fnl)"
    ;;   {})
    (case opts.cmdline-key
      false nil
      "" nil
      key (do
            (vim.api.nvim_set_keymap :c plug-map-insert
              ;; NOTE: `v:lua` interface does not support method call.
              "<C-BSlash>ev:lua.require('thyme.user.dropin').cmdline.replace(getcmdline())<CR>"
              {:noremap true})
            ;; TODO: Expose `<Plug>` keymaps once stable a bit.
            (vim.api.nvim_set_keymap :c key (.. plug-map-insert "<CR>")
              {:noremap true})))
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
  (set M.cmdline {:replace (fn [old-cmdline]
                             (let [cmdtype (vim.fn.getcmdtype)]
                               (if (or (= ":" cmdtype) debug?)
                                   (let [dropin (DropinCmdline.new cmdtype
                                                                   registry
                                                                   old-cmdline)]
                                     (dropin:replace-cmdline!))
                                   old-cmdline)))
                  :complete (fn [old-cmdline]
                              (let [cmdtype (vim.fn.getcmdtype)]
                                (if (= ":" cmdtype)
                                    (let [dropin (DropinCmdline.new cmdtype
                                                                    registry
                                                                    old-cmdline)]
                                      (dropin:complete-cmdline!))
                                    old-cmdline)))})
  M)
