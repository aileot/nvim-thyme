local _local_1_ = require("thyme.util.general")
local validate_type = _local_1_["validate-type"]
local Dropin = {}
Dropin.__index = Dropin
Dropin.new = function(cmdtype, Registry, old_line)
  if (nil == old_line) then
    _G.error("Missing argument old-line on fnl/thyme/user/dropin/replacer/common.fnl:9", 2)
  else
  end
  if (nil == Registry) then
    _G.error("Missing argument Registry on fnl/thyme/user/dropin/replacer/common.fnl:9", 2)
  else
  end
  if (nil == cmdtype) then
    _G.error("Missing argument cmdtype on fnl/thyme/user/dropin/replacer/common.fnl:9", 2)
  else
  end
  local self = setmetatable({}, Dropin)
  self._cmdtype = cmdtype
  self._registry = Registry
  validate_type("string", old_line)
  self["_old-line"] = old_line
  return self
end
Dropin["restore-old-cmdhist!"] = function(self)
  local old_cmdline = self["_old-line"]
  local function _5_()
    return assert((1 == vim.fn.histadd(self._cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
  end
  return vim.schedule(_5_)
end
Dropin["_extract-?invalid-cmd"] = function(self, cmdline)
  if (nil == cmdline) then
    _G.error("Missing argument cmdline on fnl/thyme/user/dropin/replacer/common.fnl:30", 2)
  else
  end
  if (nil == self) then
    _G.error("Missing argument self on fnl/thyme/user/dropin/replacer/common.fnl:30", 2)
  else
  end
  local case_8_, case_9_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if ((case_8_ == false) and (nil ~= case_9_)) then
    local msg = case_9_
    local expected_error_msg_prefix = "E492: Not an editor command: (.*)"
    return msg:match(expected_error_msg_prefix)
  elseif ((case_8_ == true) and ((_G.type(case_9_) == "table") and (nil ~= case_9_.nextcmd))) then
    local nextcmd = case_9_.nextcmd
    if not ("" == nextcmd) then
      return self["_extract-?invalid-cmd"](self, nextcmd)
    else
      return nil
    end
  else
    return nil
  end
end
Dropin["_replace-invalid-cmdline"] = function(self, old_cmdline, invalid_cmd)
  if (nil == invalid_cmd) then
    _G.error("Missing argument invalid-cmd on fnl/thyme/user/dropin/replacer/common.fnl:44", 2)
  else
  end
  if (nil == old_cmdline) then
    _G.error("Missing argument old-cmdline on fnl/thyme/user/dropin/replacer/common.fnl:44", 2)
  else
  end
  if (nil == self) then
    _G.error("Missing argument self on fnl/thyme/user/dropin/replacer/common.fnl:44", 2)
  else
  end
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd
  do
    local new_cmd = invalid_cmd
    for _, _15_ in self._registry:iter() do
      local pattern = _15_.pattern
      local replacement = _15_.replacement
      if (new_cmd ~= invalid_cmd) then break end
      new_cmd = invalid_cmd:gsub(pattern, replacement)
    end
    fallback_cmd = new_cmd
  end
  local new_cmdline = (prefix .. fallback_cmd)
  return new_cmdline
end
Dropin["normalize-cmdline"] = function(self)
  local old_line = self["_old-line"]
  local _17_
  do
    local case_16_ = self["_extract-?invalid-cmd"](self, old_line)
    if (nil ~= case_16_) then
      local invalid_cmd = case_16_
      _17_ = self["_replace-invalid-cmdline"](self, old_line, invalid_cmd)
    else
      _17_ = nil
    end
  end
  return (_17_ or old_line)
end
return Dropin
