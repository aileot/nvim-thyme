(local Config (require :thyme.config))
(local {: debug?} (require :thyme.const))
(local DropinRegistry (require :thyme.user.dropin.registry))
(local DropinCmdline (require :thyme.user.dropin.replacer.cmdline))
(local DropinCmdwin (require :thyme.user.dropin.replacer.cmdwin))

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

(fn map-keys-in-cmdwin! [buf]
  (let [plug-map-insert "<Plug>(thyme-dropin-insert-Fnl-if-needed)"]
    (vim.api.nvim_set_keymap :n plug-map-insert
      "<Cmd>lua require('thyme.user.dropin').cmdwin.replace(vim.fn.line('.'))<CR>"
      {:noremap true})
    (vim.api.nvim_set_keymap :i plug-map-insert
      "<Cmd>lua require('thyme.user.dropin').cmdwin.replace(vim.fn.line('.'))<CR>"
      {:noremap true})
    (case Config.dropin.cmdwin.enter-key
      false nil
      "" nil
      key (do
            ;; TODO: Are they worth letting users map different keys in individual options?
            (vim.api.nvim_buf_set_keymap buf :n key (.. plug-map-insert "<CR>")
                                         {:noremap true :nowait true})
            (vim.api.nvim_buf_set_keymap buf :i key (.. plug-map-insert "<CR>")
                                         {:noremap true :nowait true})))))

(fn M.enable-dropin-paren! []
  "Realize dropin-paren feature.
The configurations are only modifiable at the `dropin-parens` attributes in `.nvim-thyme.fnl`."
  ;; TODO: Extract dropin feature into another plugin.
  ;; TODO: Merge the dropin options to `command.dropin`?
  ;; TODO: Support cmdwin.
  ;; (each [_ key (ipairs opts.dropin-parens.cmdwin)]
  ;;   (vim.api.nvim_set_keymap :n key "<Plug>(thyme-precede-paren-by-Fnl)"
  ;;     {:noremap true}))
  (map-keys-in-cmdline!)
  (let [group (vim.api.nvim_create_augroup :ThymeDropinCmdwin {})]
    (vim.api.nvim_create_autocmd :CmdWinEnter
      {: group :pattern ":" :callback #(map-keys-in-cmdwin! $.buf)})))

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
  (set M.cmdwin
       {:replace (fn [row]
                   (let [cmdtype (vim.fn.getcmdwintype)]
                     (if (or (= ":" cmdtype) debug?)
                         (let [dropin (DropinCmdwin.new cmdtype registry row)]
                           (dropin:replace-cmdline!)))))})
  M)
