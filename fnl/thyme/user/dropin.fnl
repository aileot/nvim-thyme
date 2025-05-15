(local M {})

(fn M.reserve [pattern replacement]
  "Reserve `replacement` to replace invalid cmdline when `pattern` is
detected with E492. The fallback command will pretend that the substrings
matched by `pattern`, and the rests behind, are the arguments of `replacement`.
@param replacement string The dropin command
@param pattern string Lua patterns to be support dropin fallback."
  (let [cmdtype (vim.fn.getcmdtype)
        old-cmdline (vim.fn.getcmdline)]
    ;; NOTE: nvim_parse_cmd should not parse ":(foobar)" with the following error:
    ;; "Parsing command-line: E492: Not an editor command: (foobar)"
    (case (pcall vim.api.nvim_parse_cmd old-cmdline {})
      true old-cmdline
      (false msg)
      (let [expected-error-msg-prefix "Parsing command%-line: E492: Not an editor command: (.*)"]
        (case (msg:match expected-error-msg-prefix)
          invalid-cmd (let [prefix (old-cmdline:sub 1
                                                    (- -1 (length invalid-cmd)))
                            fallback-cmd (invalid-cmd:gsub pattern replacement)
                            new-cmdline (.. prefix fallback-cmd)]
                        ;; Add the original command to history to match with
                        ;; `<Up>` in cmdline.
                        ;; NOTE: vim.schedule is required to modify the cmdline
                        ;; history when the attempt runs in cmdline.
                        (-> #(assert (= 1 (vim.fn.histadd cmdtype old-cmdline))
                                     (.. "failed to add old command "
                                         old-cmdline))
                            (vim.schedule))
                        new-cmdline)
          _ old-cmdline)))))

(λ M.enable-dropin-paren! [opts]
  "Realize dropin-paren feature.
@param opts.cmap string (default \"<CR>\") The keys to be mapped in Cmdline mode."
  ;; TODO: Support cmdwin.
  ;; (each [_ key (ipairs opts.dropin-parens.cmdwin)]
  ;;   (vim.api.nvim_set_keymap :n key "<Plug>(thyme-precede-paren-by-Fnl)"
  ;;     {:noremap true}))
  ;; (vim.api.nvim_set_keymap :c "<C-j>" "<Plug>(thyme-precede-paren-by-Fnl)"
  ;;   {})
  (each [_ key (ipairs opts.cmdline-maps)]
    (vim.api.nvim_set_keymap :c key
      "<C-BSlash>ev:lua.require('thyme.user.dropin').reserve('[%[%(%{]].*','Fnl %0')<CR><CR>"
      {:noremap true})))

M
