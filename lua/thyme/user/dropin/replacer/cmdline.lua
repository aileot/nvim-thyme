local function extract__3finvalid_cmd(cmdline)
  local _1_, _2_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if ((_1_ == false) and (nil ~= _2_)) then
    local msg = _2_
    local expected_error_msg_prefix = "Parsing command%-line: E492: Not an editor command: (.*)"
    return msg:match(expected_error_msg_prefix)
  elseif ((_1_ == true) and ((_G.type(_2_) == "table") and (nil ~= _2_.nextcmd))) then
    local nextcmd = _2_.nextcmd
    if not ("" == nextcmd) then
      return extract__3finvalid_cmd(nextcmd)
    else
      return nil
    end
  else
    return nil
  end
end
local Dropin = {}
Dropin.__index = Dropin
Dropin.new = function(Registry)
  local self = setmetatable({}, Dropin)
  self._registry = Registry
  return self
end
Dropin["_replace-invalid-cmdline"] = function(self, old_cmdline, invalid_cmd)
  _G.assert((nil ~= invalid_cmd), "Missing argument invalid-cmd on fnl/thyme/user/dropin/replacer/cmdline.fnl:29")
  _G.assert((nil ~= old_cmdline), "Missing argument old-cmdline on fnl/thyme/user/dropin/replacer/cmdline.fnl:29")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin/replacer/cmdline.fnl:29")
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd
  do
    local new_cmd = invalid_cmd
    for _, _5_ in self._registry:iter() do
      local pattern = _5_["pattern"]
      local replacement = _5_["replacement"]
      if (new_cmd ~= invalid_cmd) then break end
      new_cmd = invalid_cmd:gsub(pattern, replacement)
    end
    fallback_cmd = new_cmd
  end
  local new_cmdline = (prefix .. fallback_cmd)
  return new_cmdline
end
Dropin["replace-cmdline!"] = function(self, old_cmdline)
  local _7_
  do
    local _6_ = extract__3finvalid_cmd(old_cmdline)
    if (nil ~= _6_) then
      local invalid_cmd = _6_
      local cmdtype = ":"
      local new_cmdline = self["_replace-invalid-cmdline"](self, old_cmdline, invalid_cmd)
      local function _10_()
        return assert((1 == vim.fn.histadd(cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
      end
      vim.schedule(_10_)
      _7_ = new_cmdline
    else
      _7_ = nil
    end
  end
  return (_7_ or old_cmdline)
end
Dropin["complete-cmdline!"] = function(self)
  local old_cmdline = vim.fn.getcmdline()
  local new_cmdline
  local _13_
  do
    local _12_ = extract__3finvalid_cmd(old_cmdline)
    if (nil ~= _12_) then
      local invalid_cmd = _12_
      _13_ = self["_replace-invalid-cmdline"](self, old_cmdline, invalid_cmd)
    else
      _13_ = nil
    end
  end
  new_cmdline = (_13_ or old_cmdline)
  local last_lz = vim.o.lazyredraw
  local last_wcm = vim.o.wildcharm
  local tmp_wcm = ""
  local right_keys
  do
    local _16_ = old_cmdline:find(new_cmdline, 1, true)
    if (_16_ == nil) then
      right_keys = ""
    elseif (nil ~= _16_) then
      local shift = _16_
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
return Dropin
