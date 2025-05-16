(import-macros {: dec} :thyme.macros)

(local M {})

(fn extract-?invalid-cmd [cmdline]
  "Extract the invalid command from cmdline from E492 message."
  ;; NOTE: nvim_parse_cmd should not parse ":(foobar)" with the following error:
  ;; "Parsing command-line: E492: Not an editor command: (foobar)"
  ;; TODO: Parse "nextcmd" recursively.
  (case (pcall vim.api.nvim_parse_cmd cmdline {})
    true cmdline
    (false msg)
    (let [expected-error-msg-prefix "Parsing command%-line: E492: Not an editor command: (.*)"]
      (msg:match expected-error-msg-prefix))))

(fn replace-invalid-cmdline [old-cmdline invalid-cmd pattern replacement]
  "Replace `pattern` matched in `old-cmdline` at `invalid-cmd` with `replacement`
@param invalid-cmd string Expected a substring of `old-cmdline`
@param old-cmdline string The original cmdline
@param pattern string Lua pattern to be replaced
@param replacement string The replacement
@return string A new cmdline"
  (let [prefix (old-cmdline:sub 1 (- -1 (length invalid-cmd)))
        fallback-cmd (invalid-cmd:gsub pattern replacement)
        new-cmdline (.. prefix fallback-cmd)]
    new-cmdline))

(fn M.reserve [pattern replacement]
  "Reserve `replacement` to replace invalid cmdline when `pattern` is
detected with E492. The fallback command will pretend that the substrings
matched by `pattern`, and the rests behind, are the arguments of `replacement`.
@param pattern string Lua patterns to be support dropin fallback.
@param replacement string The dropin command"
  (let [old-cmdline (vim.fn.getcmdline)]
    (case (extract-?invalid-cmd old-cmdline)
      invalid-cmd (let [cmdtype (vim.fn.getcmdtype)
                        new-cmdline (replace-invalid-cmdline old-cmdline ;
                                                             invalid-cmd ;
                                                             pattern ;
                                                             replacement)]
                    ;; `<Up>` in cmdline.
                    ;; NOTE: vim.schedule is required to modify the cmdline
                    ;; history when the attempt runs in cmdline.
                    (-> #(assert (= 1 (vim.fn.histadd cmdtype old-cmdline))
                                 (.. "failed to add old command " old-cmdline))
                        (vim.schedule))
                    new-cmdline)
      _ old-cmdline)))

(fn M.complete [pattern replacement]
  "Complete cmdline pretending `replacement` to replace invalid cmdline when
`pattern` is detected with E492.
@param pattern string string Lua patterns to be support dropin fallback.
@param replacement string The dropin command
@param completion-type string The completion type"
  (let [old-cmdline (vim.fn.getcmdline)]
    ;; NOTE: Do NOT use .reserve instead. It also overrides history.
    (case (extract-?invalid-cmd old-cmdline)
      invalid-cmd (let [new-cmdline (replace-invalid-cmdline old-cmdline ;
                                                             invalid-cmd ;
                                                             pattern ;
                                                             replacement)
                        last-wcm vim.o.wildcharm
                        tmp-wcm "\26"
                        right-keys (case (new-cmdline:find old-cmdline 1 true)
                                     nil ""
                                     shift (string.rep "<Right>" (dec shift)))
                        keys (-> (.. "<C-BSlash>e%q<CR>")
                                 (: :format new-cmdline)
                                 (.. right-keys)
                                 (vim.keycode)
                                 (.. tmp-wcm))]
                    (set vim.o.wcm (vim.fn.str2nr tmp-wcm))
                    (vim.api.nvim_feedkeys keys "ni" false)
                    (set vim.o.wcm last-wcm)))))

(λ M.enable-dropin-paren! [opts]
  "Realize dropin-paren feature.
@param opts.cmap string (default \"<CR>\") The keys to be mapped in Cmdline mode."
  (let [plug-map-insert "<Plug>(thyme-dropin-insert-Fnl)"
        plug-map-complete "<Plug>(thyme-dropin-complete-Fnl)"]
    ;; TODO: Support cmdwin.
    ;; (each [_ key (ipairs opts.dropin-parens.cmdwin)]
    ;;   (vim.api.nvim_set_keymap :n key "<Plug>(thyme-precede-paren-by-Fnl)"
    ;;     {:noremap true}))
    ;; (vim.api.nvim_set_keymap :c "<C-j>" "<Plug>(thyme-precede-paren-by-Fnl)"
    ;;   {})
    (case opts.cmdline-key
      false nil
      "" nil
      key (do
            (vim.api.nvim_set_keymap :c plug-map-insert
              "<C-BSlash>ev:lua.require('thyme.user.dropin').reserve('^[%[%(%{].*','Fnl %0')<CR><CR>"
              {:noremap true})
            ;; TODO: Expose `<Plug>` keymaps once stable a bit.
            (vim.api.nvim_set_keymap :c key plug-map-insert {:noremap true})))
    (case opts.cmdline-completion-key
      false nil
      "" nil
      key (do
            (vim.api.nvim_set_keymap :c plug-map-complete
              "<Cmd>lua require('thyme.user.dropin').complete('^[%[%(%{].*','Fnl %0')<CR>"
              {:noremap true})
            (vim.api.nvim_set_keymap :c key plug-map-complete {:noremap true})))))

M
