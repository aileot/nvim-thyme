(import-macros {: dec} :thyme.macros)

(local Dropin (require :thyme.user.dropin.replacer.common))

(local DropinCmdwin (setmetatable {} {:__index Dropin}))

(set DropinCmdwin.__index DropinCmdwin)

(fn validate-in-cmdwin! []
  (let [wintype (vim.fn.win_gettype)]
    (assert (= "command" wintype) (.. "expected in cmdwin, but in " wintype))))

(fn DropinCmdwin.new [cmdtype Registry row]
  (validate-in-cmdwin!)
  (let [buf (vim.api.nvim_get_current_buf)
        row01 (dec row)
        row02 row
        [old-line] (vim.api.nvim_buf_get_lines buf row01 row02 true)
        parent (Dropin.new cmdtype Registry old-line)
        self (setmetatable parent DropinCmdwin)]
    (set self._buf buf)
    (set self._row row)
    self))

(fn DropinCmdwin.replace-cmdline! [self]
  (let [buf self._buf
        row01 (dec self._row)
        row02 self._row
        new-line (self:normalize-cmdline)
        new-lines [new-line]]
    (vim.api.nvim_buf_set_lines buf row01 row02 true new-lines)
    (self:restore-old-cmdhist!)))

DropinCmdwin
