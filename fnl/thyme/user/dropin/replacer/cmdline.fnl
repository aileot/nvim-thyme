(import-macros {: when-not : dec} :thyme.macros)

(local Dropin (require :thyme.user.dropin.replacer.common))

(local DropinCmdline (setmetatable {} {:__index Dropin}))

(set DropinCmdline.__index DropinCmdline)

(fn DropinCmdline.new [cmdtype Registry old-cmdline]
  "Create a new dropin instance.
@param Registry Registry
@param old-cmdline string line to be normalized
@return Dropin"
  (let [parent (Dropin.new cmdtype Registry old-cmdline)
        self (setmetatable parent DropinCmdline)]
    self))

(fn Dropin.replace-cmdline! [self]
  "Prepare to replace `replacement` to replace invalid cmdline when `pattern`
is detected with E492. The fallback command will pretend that the substrings
matched by `pattern`, and the rests behind, are the arguments of
`replacement`.
@return string A new cmdline"
  (let [new-cmdline (self:normalize-cmdline)]
    (self:restore-old-cmdhist!)
    (-> "<C-BSlash>e%q<CR>"
        (: :format new-cmdline))))

(fn DropinCmdline.complete-cmdline! [self]
  "Complete cmdline pretending `replacement` to replace invalid cmdline when
`pattern` is detected with E492."
  (let [old-cmdline (vim.fn.getcmdline)
        ;; NOTE: Do NOT use .replace instead. It also overrides history.
        new-cmdline (self:normalize-cmdline)
        last-wcm vim.o.wildcharm
        tmp-wcm "<C-z>"
        right-keys (case (old-cmdline:find new-cmdline 1 true)
                     nil ""
                     shift (string.rep "<Right>" (dec shift)))
        keys (-> "<C-BSlash>e%q<CR>"
                 (: :format new-cmdline)
                 (.. right-keys)
                 (.. "<Cmd>set wcm=" (vim.keycode tmp-wcm) "<CR>")
                 (.. tmp-wcm)
                 (.. "<Cmd>set wcm=" last-wcm "<CR>"))]
    keys))

DropinCmdline
