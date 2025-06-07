local Dropin = require("thyme.user.dropin.replacer.common")
local DropinCmdline = setmetatable({}, {__index = Dropin})
DropinCmdline.__index = DropinCmdline
DropinCmdline.new = function(cmdtype, Registry, old_cmdline)
  local parent = Dropin.new(cmdtype, Registry, old_cmdline)
  local self = setmetatable(parent, DropinCmdline)
  return self
end
Dropin["replace-cmdline!"] = function(self)
  local new_cmdline = self["normalize-cmdline"](self)
  self["restore-old-cmdhist!"](self)
  return new_cmdline
end
DropinCmdline["complete-cmdline!"] = function(self)
  local old_cmdline = vim.fn.getcmdline()
  local new_cmdline = self["normalize-cmdline"](self)
  local last_lz = vim.o.lazyredraw
  local last_wcm = vim.o.wildcharm
  local tmp_wcm = ""
  local right_keys
  do
    local _1_ = old_cmdline:find(new_cmdline, 1, true)
    if (_1_ == nil) then
      right_keys = ""
    elseif (nil ~= _1_) then
      local shift = _1_
      right_keys = string.rep("<Right>", (shift - 1))
    else
      right_keys = nil
    end
  end
  local keys = (vim.keycode((("<C-BSlash>e%q<CR>"):format(new_cmdline) .. right_keys)) .. tmp_wcm)
  vim.o.wcm = vim.fn.str2nr(tmp_wcm)
  vim.o.lazyredraw = true
  vim.api.nvim_feedkeys(keys, "ni", false)
  vim.o.wcm = last_wcm
  vim.o.lazyredraw = last_lz
  return nil
end
return DropinCmdline
