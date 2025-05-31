(import-macros {: dec} :thyme.macros)

(local Config (require :thyme.config))

(fn get-cmdtype []
  "A wrapper to tell the current command type."
  ;; TODO: Does it support cmdbuf-like plugins?
  (if (= "command" (vim.fn.win_gettype))
      (vim.fn.getcmdwintype)
      (vim.fn.getcmdtype)))

(fn extract-?invalid-cmd [cmdline]
  "Extract the invalid command from cmdline from E492 message.
@param cmdline string The command line to be parsed
@return string The invalid command if detected, otherwise nil."
  ;; NOTE: nvim_parse_cmd should not parse ":(foobar)" with the following error:
  ;; "Parsing command-line: E492: Not an editor command: (foobar)"
  ;; TODO: Parse "nextcmd" recursively.
  (case (pcall vim.api.nvim_parse_cmd cmdline {})
    (false msg)
    (let [expected-error-msg-prefix "Parsing command%-line: E492: Not an editor command: (.*)"]
      (msg:match expected-error-msg-prefix))))

(local Dropin {})

(set Dropin.__index Dropin)

(fn Dropin._new []
  "Create a new dropin instance."
  (let [self (setmetatable {} Dropin)]
    (set self._commands {})
    self))

(λ Dropin._replace-invalid-cmdline [self old-cmdline invalid-cmd]
  "Replace `pattern` matched in `old-cmdline` at `invalid-cmd` with `replacement`
@param invalid-cmd string Expected a substring of `old-cmdline`
@param old-cmdline string The original cmdline
@return string A new cmdline"
  (let [prefix (old-cmdline:sub 1 (- -1 (length invalid-cmd)))
        fallback-cmd (accumulate [new-cmd invalid-cmd ;
                                  _ {: pattern : replacement} (ipairs self._commands)
                                  &until (not= new-cmd invalid-cmd)]
                       (invalid-cmd:gsub pattern replacement))
        new-cmdline (.. prefix fallback-cmd)]
    new-cmdline))

(fn Dropin.replace-cmdline! [self]
  "Prepare to replace `replacement` to replace invalid cmdline when `pattern` is
detected with E492. The fallback command will pretend that the substrings
matched by `pattern`, and the rests behind, are the arguments of `replacement`.
@param pattern string Lua patterns to be support dropin fallback.
@param replacement string The dropin command"
  (let [cmdtype (get-cmdtype)
        old-cmdline (vim.fn.getcmdline)]
    (or (case (when (= ":" cmdtype)
                (extract-?invalid-cmd old-cmdline))
          invalid-cmd (let [new-cmdline (self:_replace-invalid-cmdline old-cmdline
                                                                       invalid-cmd)]
                        ;; `<Up>` in cmdline.
                        ;; NOTE: vim.schedule is required to modify the cmdline
                        ;; history when the attempt runs in cmdline.
                        (-> #(assert (= 1 (vim.fn.histadd cmdtype old-cmdline))
                                     (.. "failed to add old command "
                                         old-cmdline))
                            (vim.schedule))
                        new-cmdline)) ;
        old-cmdline)))

(fn Dropin.complete-cmdline! [self]
  "Complete cmdline pretending `replacement` to replace invalid cmdline when
`pattern` is detected with E492.
@param pattern string string Lua patterns to be support dropin fallback.
@param replacement string The dropin command
@param completion-type string The completion type"
  (let [cmdtype (get-cmdtype)
        old-cmdline (vim.fn.getcmdline)
        ;; NOTE: Do NOT use .replace instead. It also overrides history.
        new-cmdline (or (case (when (= ":" cmdtype)
                                (extract-?invalid-cmd old-cmdline))
                          invalid-cmd (self:_replace-invalid-cmdline old-cmdline
                                                                     invalid-cmd))
                        old-cmdline)
        last-lz vim.o.lazyredraw
        last-wcm vim.o.wildcharm
        tmp-wcm "\26"
        right-keys (case (new-cmdline:find old-cmdline 1 true)
                     nil ""
                     shift (string.rep "<Right>" (dec shift)))
        keys (-> "<C-BSlash>e%q<CR>"
                 (: :format new-cmdline)
                 (.. right-keys)
                 (vim.keycode)
                 (.. tmp-wcm))]
    (set vim.o.wcm (vim.fn.str2nr tmp-wcm))
    (set vim.o.lazyredraw true)
    (vim.api.nvim_feedkeys keys "ni" false)
    (set vim.o.wcm last-wcm)
    (set vim.o.lazyredraw last-lz)))

(λ Dropin.register! [self pattern replacement]
  "Register a pair of `pattern` and `replacement` to dropin.
@param pattern string Lua patterns to be support dropin fallback.
@param replacement string The dropin command"
  (table.insert self._commands {: pattern : replacement}))

(fn Dropin.enable-dropin-paren! [self]
  "Realize dropin-paren feature.
The configurations are only modifiable at the `dropin-parens` attributes in `.nvim-thyme.fnl`."
  ;; TODO: Extract dropin feature into another plugin.
  ;; TODO: Merge the dropin options to `command.dropin`?
  (self:register! "^[[%[%(%{].*" "Fnl %0")
  (let [opts Config.dropin-paren
        plug-map-insert "<Plug>(thyme-dropin-insert-Fnl)"
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
              ;; NOTE: `v:lua` interface does not support method call.
              "<C-BSlash>ev:lua.require('thyme.user.dropin').replace()<CR><CR>"
              {:noremap true})
            ;; TODO: Expose `<Plug>` keymaps once stable a bit.
            (vim.api.nvim_set_keymap :c key plug-map-insert {:noremap true})))
    (case opts.cmdline-completion-key
      false nil
      "" nil
      key (do
            (vim.api.nvim_set_keymap :c plug-map-complete
              "<Cmd>lua require('thyme.user.dropin').complete()<CR>"
              {:noremap true})
            (vim.api.nvim_set_keymap :c key plug-map-complete {:noremap true})))))

(let [SingletonDropin (Dropin._new)]
  {:register (fn [...]
               (SingletonDropin:register! ...))
   :replace (fn [...]
              (SingletonDropin:replace-cmdline! ...))
   :complete (fn [...]
               (SingletonDropin:complete-cmdline! ...))
   :enable-dropin-paren! (fn []
                           (SingletonDropin:enable-dropin-paren!))})
