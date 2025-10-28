local _local_1_ = require("thyme.util.general")
local validate_type = _local_1_["validate-type"]
local Dropin = {}
Dropin.__index = Dropin
Dropin.new = function(cmdtype, Registry, old_line)
  _G.assert((nil ~= old_line), "Missing argument old-line on fnl/thyme/user/dropin/replacer/common.fnl:9")
  _G.assert((nil ~= Registry), "Missing argument Registry on fnl/thyme/user/dropin/replacer/common.fnl:9")
  _G.assert((nil ~= cmdtype), "Missing argument cmdtype on fnl/thyme/user/dropin/replacer/common.fnl:9")
  local self = setmetatable({}, Dropin)
  self._cmdtype = cmdtype
  self._registry = Registry
  validate_type("string", old_line)
  self["_old-line"] = old_line
  return self
end
Dropin["restore-old-cmdhist!"] = function(self)
  local old_cmdline = self["_old-line"]
  local function _2_()
    return assert((1 == vim.fn.histadd(self._cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
  end
  return vim.schedule(_2_)
end
Dropin["_extract-?invalid-cmd"] = function(self, cmdline)
  _G.assert((nil ~= cmdline), "Missing argument cmdline on fnl/thyme/user/dropin/replacer/common.fnl:30")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin/replacer/common.fnl:30")
  local _3_, _4_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if ((_3_ == false) and (nil ~= _4_)) then
    local msg = _4_
    local expected_error_msg_prefix = "E492: Not an editor command: (.*)"
    return msg:match(expected_error_msg_prefix)
  elseif ((_3_ == true) and ((_G.type(_4_) == "table") and (nil ~= _4_.nextcmd))) then
    local nextcmd = _4_.nextcmd
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
  _G.assert((nil ~= invalid_cmd), "Missing argument invalid-cmd on fnl/thyme/user/dropin/replacer/common.fnl:44")
  _G.assert((nil ~= old_cmdline), "Missing argument old-cmdline on fnl/thyme/user/dropin/replacer/common.fnl:44")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin/replacer/common.fnl:44")
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd
  do
    local new_cmd = invalid_cmd
    for _, _7_ in self._registry:iter() do
      local pattern = _7_["pattern"]
      local replacement = _7_["replacement"]
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
  local _9_
  do
    local _8_ = self["_extract-?invalid-cmd"](self, old_line)
    if (nil ~= _8_) then
      local invalid_cmd = _8_
      _9_ = self["_replace-invalid-cmdline"](self, old_line, invalid_cmd)
    else
      _9_ = nil
    end
  end
  return (_9_ or old_line)
end
return Dropin
