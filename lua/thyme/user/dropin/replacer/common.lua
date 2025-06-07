local Dropin = {}
Dropin.__index = Dropin
Dropin.new = function(cmdtype, Registry, old_line)
  _G.assert((nil ~= old_line), "Missing argument old-line on fnl/thyme/user/dropin/replacer/common.fnl:7")
  _G.assert((nil ~= Registry), "Missing argument Registry on fnl/thyme/user/dropin/replacer/common.fnl:7")
  _G.assert((nil ~= cmdtype), "Missing argument cmdtype on fnl/thyme/user/dropin/replacer/common.fnl:7")
  local self = setmetatable({}, Dropin)
  self._cmdtype = cmdtype
  self._registry = Registry
  self["_old-line"] = old_line
  return self
end
Dropin["restore-old-cmdhist!"] = function(self)
  local old_cmdline = self["_old-line"]
  local function _1_()
    return assert((1 == vim.fn.histadd(self._cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
  end
  return vim.schedule(_1_)
end
Dropin["_extract-?invalid-cmd"] = function(self, cmdline)
  _G.assert((nil ~= cmdline), "Missing argument cmdline on fnl/thyme/user/dropin/replacer/common.fnl:27")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin/replacer/common.fnl:27")
  local _2_, _3_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if ((_2_ == false) and (nil ~= _3_)) then
    local msg = _3_
    local expected_error_msg_prefix = "E492: Not an editor command: (.*)"
    return msg:match(expected_error_msg_prefix)
  elseif ((_2_ == true) and ((_G.type(_3_) == "table") and (nil ~= _3_.nextcmd))) then
    local nextcmd = _3_.nextcmd
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
  _G.assert((nil ~= invalid_cmd), "Missing argument invalid-cmd on fnl/thyme/user/dropin/replacer/common.fnl:41")
  _G.assert((nil ~= old_cmdline), "Missing argument old-cmdline on fnl/thyme/user/dropin/replacer/common.fnl:41")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin/replacer/common.fnl:41")
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd
  do
    local new_cmd = invalid_cmd
    for _, _6_ in self._registry:iter() do
      local pattern = _6_["pattern"]
      local replacement = _6_["replacement"]
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
  local _8_
  do
    local _7_ = self["_extract-?invalid-cmd"](self, old_line)
    if (nil ~= _7_) then
      local invalid_cmd = _7_
      _8_ = self["_replace-invalid-cmdline"](self, old_line, invalid_cmd)
    else
      _8_ = nil
    end
  end
  return (_8_ or old_line)
end
return Dropin
