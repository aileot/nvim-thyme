(import-macros {: when-not : dec} :thyme.macros)

(fn extract-?invalid-cmd [cmdline]
  "Extract the invalid command from cmdline from E492 message.
@param cmdline string The command line to be parsed
@return string? The invalid command if detected, otherwise nil."
  ;; NOTE: nvim_parse_cmd should not parse ":(foobar)" with the following error:
  ;; "Parsing command-line: E492: Not an editor command: (foobar)"
  ;; TODO: Parse "nextcmd" recursively.
  (case (pcall vim.api.nvim_parse_cmd cmdline {})
    (false msg)
    (let [expected-error-msg-prefix "Parsing command%-line: E492: Not an editor command: (.*)"]
      (msg:match expected-error-msg-prefix))
    (true {: nextcmd}) (when-not (= "" nextcmd)
                         (extract-?invalid-cmd nextcmd))))

(local Dropin {})

(set Dropin.__index Dropin)

(fn Dropin.new [Registry]
  "Create a new dropin instance.
@param Registry Registry
@return Dropin"
  (let [self (setmetatable {} Dropin)]
    (set self._registry Registry)
    self))

(λ Dropin._replace-invalid-cmdline [self old-cmdline invalid-cmd]
  "Replace `pattern` matched in `old-cmdline` at `invalid-cmd` with `replacement`
@param invalid-cmd string Expected a substring of `old-cmdline`
@param old-cmdline string The original cmdline
@return string A new cmdline"
  (let [prefix (old-cmdline:sub 1 (- -1 (length invalid-cmd)))
        fallback-cmd (accumulate [new-cmd invalid-cmd ;
                                  _ {: pattern : replacement} (self._registry:iter)
                                  &until (not= new-cmd invalid-cmd)]
                       (invalid-cmd:gsub pattern replacement))
        new-cmdline (.. prefix fallback-cmd)]
    new-cmdline))

(fn Dropin.replace-cmdline! [self old-cmdline]
  "Prepare to replace `replacement` to replace invalid cmdline when `pattern` is
detected with E492. The fallback command will pretend that the substrings
matched by `pattern`, and the rests behind, are the arguments of `replacement`.
@param old-cmdline string The original cmdline
@return string A new cmdline replaced a pre-registered `pattern` with `replacement`."
  (or (case (extract-?invalid-cmd old-cmdline)
        invalid-cmd (let [cmdtype ":"
                          new-cmdline (self:_replace-invalid-cmdline old-cmdline
                                                                     invalid-cmd)]
                      ;; NOTE: vim.schedule is required to modify the cmdline
                      ;; history when the attempt runs in cmdline.
                      (-> #(assert (= 1 (vim.fn.histadd cmdtype old-cmdline))
                                   (.. "failed to add old command " old-cmdline))
                          (vim.schedule))
                      new-cmdline)) ;
      old-cmdline))

(fn Dropin.complete-cmdline! [self]
  "Complete cmdline pretending `replacement` to replace invalid cmdline when
`pattern` is detected with E492."
  (let [old-cmdline (vim.fn.getcmdline)
        ;; NOTE: Do NOT use .replace instead. It also overrides history.
        new-cmdline (or (case (extract-?invalid-cmd old-cmdline)
                          invalid-cmd (self:_replace-invalid-cmdline old-cmdline
                                                                     invalid-cmd))
                        old-cmdline)
        last-lz vim.o.lazyredraw
        last-wcm vim.o.wildcharm
        tmp-wcm "\26"
        right-keys (case (old-cmdline:find new-cmdline 1 true)
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

Dropin
