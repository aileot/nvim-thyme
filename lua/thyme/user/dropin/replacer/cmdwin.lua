local Dropin = require("thyme.user.dropin.replacer.common")
local DropinCmdwin = setmetatable({}, {__index = Dropin})
DropinCmdwin.__index = DropinCmdwin
local function validate_in_cmdwin_21()
  local wintype = vim.fn.win_gettype()
  return assert(("command" == wintype), ("expected in cmdwin, but in " .. wintype))
end
DropinCmdwin.new = function(cmdtype, Registry, row)
  validate_in_cmdwin_21()
  local buf = vim.api.nvim_get_current_buf()
  local row01 = (row - 1)
  local row02 = row
  local _let_1_ = vim.api.nvim_buf_get_lines(buf, row01, row02, true)
  local old_line = _let_1_[1]
  local parent = Dropin.new(cmdtype, Registry, old_line)
  local self = setmetatable(parent, DropinCmdwin)
  self._buf = buf
  self._row = row
  return self
end
DropinCmdwin["replace-cmdline!"] = function(self)
  local buf = self._buf
  local row01 = (self._row - 1)
  local row02 = self._row
  local new_line = self["normalize-cmdline"](self)
  local new_lines = {new_line}
  vim.api.nvim_buf_set_lines(buf, row01, row02, true, new_lines)
  return self["restore-old-cmdhist!"](self)
end
return DropinCmdwin
