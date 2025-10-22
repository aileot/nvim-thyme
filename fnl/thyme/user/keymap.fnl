(import-macros {: str? : inc : first} :thyme.macros)

(local fennel (require :fennel))

(local tts (require :thyme.treesitter))

(local fennel-wrapper (require :thyme.wrapper.fennel))

(local {: buf-marks->text} (require :thyme.util.buf))

(local Config (require :thyme.lazy-config))

(local M {})

(local Keymap {})

(set Keymap.__index Keymap)

(fn Keymap.new [{: backend : lang}]
  ;; NOTE: &operatorfunc does not work on v:lua.require('foo')['bar'] format
  ;; instead of v:lua.require'foo'.bar: both `()` and `[]` do matter, avoid
  ;; "-" in names.
  (let [self (setmetatable {} Keymap)]
    (set self._module-name :thyme.user.keymap)
    (set self._callback-prefix :new_operator_)
    (set self._operator-callback-prefix :operator_)
    (set self._backend backend)
    (set self._lang lang)
    self))

(fn Keymap.generate-plug-keymaps! [self method]
  (let [keymap-suffix (.. method "-" self._backend)
        callback-suffix (keymap-suffix:gsub "%-" "_")
        callback-name (.. self._callback-prefix callback-suffix)
        callback-in-string (: "require'%s'.%s" ;
                              :format self._module-name callback-name)
        operator-callback-name (.. self._operator-callback-prefix
                                   callback-suffix)
        operator-callback-in-string (: "require'%s'.%s" ;
                                       :format self._module-name
                                       operator-callback-name)
        lhs (: "<Plug>(thyme-operator-%s)" :format keymap-suffix)
        ;; TODO: What implementation is the best for linewise operator?
        ;; NOTE: In Vim script expression, avoid double quotes.
        rhs/n (: "<Cmd>set operatorfunc=v:lua.%s<CR>g@" ;
                 :format operator-callback-in-string)
        rhs/x (: ":lua %s('<','>')<CR>" ;
                 :format callback-in-string)
        marks->print (fn [mark1 mark2]
                       (let [preproc (or Config.keymap.preproc ;
                                         Config.preproc ;
                                         (fn [fnl-code _compiler-options]
                                           fnl-code))
                             compiler-options (or Config.keymap.compiler-options
                                                  Config.compiler-options)
                             eval-fn (. fennel-wrapper self._backend)
                             print-fn (. tts method)
                             val (-> (buf-marks->text 0 mark1 mark2)
                                     (preproc compiler-options)
                                     (eval-fn compiler-options))
                             text (if (str? val)
                                      val
                                      (fennel.view val compiler-options))]
                         (print-fn text {:lang self._lang})))
        operator-callback #(marks->print "[" "]")]
    (vim.api.nvim_set_keymap :n lhs rhs/n {:noremap true})
    (vim.api.nvim_set_keymap :x lhs rhs/x {:noremap true :silent true})
    (tset M callback-name marks->print)
    (tset M operator-callback-name operator-callback)
    (vim.keymap.set [:n :x] "<Plug>(thyme-alternate-file)"
                    "<Cmd>FnlAlternate<CR>")))

(fn Keymap.map-keys-on-ft=fennel! []
  "Map keys for ft=fennel buffer."
  (let [keymap-recipes Config.keymap.mappings
        plug-keymap-template #(-> "<Plug>(thyme-%s)" (: :format $))]
    (each [mode rhs->lhs (pairs keymap-recipes)]
      (each [rhs-key lhs (pairs rhs->lhs)]
        (let [rhs (plug-keymap-template rhs-key)]
          (vim.keymap.set mode lhs rhs {:buffer true}))))
    ;; Make sure not to destroy the autocmd just in case in the future updates.
    nil))

(fn Keymap.map-keys-on-ft=lua! []
  "Map keys for ft=lua buffer."
  (let [keymap-recipes Config.keymap.mappings
        plug-keymap-template #(-> "<Plug>(thyme-%s)" (: :format $))
        lhs-rhs-pairs-on-ft=lua [:alternate-file]]
    (each [_ rhs-key (ipairs lhs-rhs-pairs-on-ft=lua)]
      (let [rhs (plug-keymap-template rhs-key)]
        (each [mode rhs->lhs (pairs keymap-recipes)]
          (case (. rhs->lhs rhs-key)
            lhs (vim.keymap.set mode lhs rhs {:buffer true})))))
    ;; Make sure not to destroy the autocmd just in case in the future updates.
    nil))

(fn define-autocmds-to-map-keys! []
  "Define autocmds on ft=fennel (and partly on ft=lua) to map keys on nvim-thyme."
  (let [group (vim.api.nvim_create_augroup "ThymeKeymap" {})]
    (vim.api.nvim_create_autocmd "FileType"
      {: group :pattern "fennel" :callback Keymap.map-keys-on-ft=fennel!})
    (vim.api.nvim_create_autocmd "FileType"
      {: group :pattern "lua" :callback Keymap.map-keys-on-ft=lua!})
    (when vim.v.vim_did_enter
      ;; Tweaks for lazy setup.
      (each [buffer (ipairs (vim.api.nvim_list_bufs))]
        (when (vim.api.nvim_buf_is_valid buffer)
          (->> #(vim.api.nvim_exec_autocmds "FileType" {: group : buffer})
               (vim.api.nvim_buf_call buffer)))))))

(fn M.define-keymaps! []
  "Define keymaps on nvim-thyme.
The configurations are only modifiable at the `keymap` attributes in
`.nvim-thyme.fnl`."
  (let [methods [:echo :print]]
    (each [_ method (ipairs methods)]
      (doto (Keymap.new {:backend "compile-string" :lang "lua"})
        (: :generate-plug-keymaps! method))
      (doto (Keymap.new {:backend "eval" :lang "fennel"})
        (: :generate-plug-keymaps! method))
      (doto (Keymap.new {:backend "eval-compiler" :lang "fennel"})
        (: :generate-plug-keymaps! method))
      (doto (Keymap.new {:backend "macrodebug" :lang "fennel"})
        (: :generate-plug-keymaps! method))))
  (define-autocmds-to-map-keys!))

M
