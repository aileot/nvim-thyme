(import-macros {: when-not : dec} :thyme.macros)

(local Dropin {})

(set Dropin.__index Dropin)

(λ Dropin.new [cmdtype Registry old-line]
  "Create a new dropin instance.
@param cmdtype string
@param Registry Registry
@param old-line string line to be normalized
@return Dropin"
  (let [self (setmetatable {} Dropin)]
    (set self._cmdtype cmdtype)
    (set self._registry Registry)
    (set self._old-line old-line)
    self))

(fn Dropin.restore-old-cmdhist! [self]
  (let [old-cmdline self._old-line]
    (-> #(assert (= 1 (vim.fn.histadd self._cmdtype old-cmdline))
                 (.. "failed to add old command " old-cmdline))
        ;; NOTE: vim.schedule is required to modify the cmdline history when the
        ;; attempt runs in cmdline.
        (vim.schedule))))

(λ Dropin._extract-?invalid-cmd [self cmdline]
  "Extract the invalid command from cmdline from E492 message.
@param cmdline string The command line to be parsed
@return string? The invalid command if detected, otherwise nil."
  ;; NOTE: nvim_parse_cmd should not parse ":(foobar)" with the following error:
  ;; "Parsing command-line: E492: Not an editor command: (foobar)"
  ;; TODO: Parse "nextcmd" recursively.
  (case (pcall vim.api.nvim_parse_cmd cmdline {})
    (false msg)
    (let [expected-error-msg-prefix "E492: Not an editor command: (.*)"]
      (msg:match expected-error-msg-prefix))
    (true {: nextcmd}) (when-not (= "" nextcmd)
                         (self:_extract-?invalid-cmd nextcmd))))

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

(fn Dropin.normalize-cmdline [self]
  "Normalize the invalid command in pre-registered `old-cmdline`.
@return string A new cmdline"
  (let [old-line self._old-line]
    (or (case (self:_extract-?invalid-cmd old-line)
          invalid-cmd (self:_replace-invalid-cmdline old-line invalid-cmd))
        old-line)))

Dropin
