local Config = require("thyme.config")
local function get_cmdtype()
  if ("command" == vim.fn.win_gettype()) then
    return vim.fn.getcmdwintype()
  else
    return vim.fn.getcmdtype()
  end
end
local function extract__3finvalid_cmd(cmdline)
  local _2_, _3_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if ((_2_ == false) and (nil ~= _3_)) then
    local msg = _3_
    local expected_error_msg_prefix = "Parsing command%-line: E492: Not an editor command: (.*)"
    return msg:match(expected_error_msg_prefix)
  elseif ((_2_ == true) and ((_G.type(_3_) == "table") and (nil ~= _3_.nextcmd))) then
    local nextcmd = _3_.nextcmd
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
Dropin._new = function()
  local self = setmetatable({}, Dropin)
  self._commands = {}
  return self
end
Dropin["_replace-invalid-cmdline"] = function(self, old_cmdline, invalid_cmd)
  _G.assert((nil ~= invalid_cmd), "Missing argument invalid-cmd on fnl/thyme/user/dropin.fnl:36")
  _G.assert((nil ~= old_cmdline), "Missing argument old-cmdline on fnl/thyme/user/dropin.fnl:36")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin.fnl:36")
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd
  do
    local new_cmd = invalid_cmd
    for _, _6_ in ipairs(self._commands) do
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
Dropin["replace-cmdline!"] = function(self)
  local cmdtype = get_cmdtype()
  local old_cmdline = vim.fn.getcmdline()
  local _8_
  do
    local _7_
    if (":" == cmdtype) then
      _7_ = extract__3finvalid_cmd(old_cmdline)
    else
      _7_ = nil
    end
    if (nil ~= _7_) then
      local invalid_cmd = _7_
      local new_cmdline = self["_replace-invalid-cmdline"](self, old_cmdline, invalid_cmd)
      local function _12_()
        return assert((1 == vim.fn.histadd(cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
      end
      vim.schedule(_12_)
      _8_ = new_cmdline
    else
      _8_ = nil
    end
  end
  return (_8_ or old_cmdline)
end
Dropin["complete-cmdline!"] = function(self)
  local cmdtype = get_cmdtype()
  local old_cmdline = vim.fn.getcmdline()
  local new_cmdline
  local _15_
  do
    local _14_
    if (":" == cmdtype) then
      _14_ = extract__3finvalid_cmd(old_cmdline)
    else
      _14_ = nil
    end
    if (nil ~= _14_) then
      local invalid_cmd = _14_
      _15_ = self["_replace-invalid-cmdline"](self, old_cmdline, invalid_cmd)
    else
      _15_ = nil
    end
  end
  new_cmdline = (_15_ or old_cmdline)
  local last_lz = vim.o.lazyredraw
  local last_wcm = vim.o.wildcharm
  local tmp_wcm = ""
  local right_keys
  do
    local _19_ = new_cmdline:find(old_cmdline, 1, true)
    if (_19_ == nil) then
      right_keys = ""
    elseif (nil ~= _19_) then
      local shift = _19_
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
Dropin["register!"] = function(self, pattern, replacement, _21_)
  local lang = _21_["lang"]
  _G.assert((nil ~= lang), "Missing argument lang on fnl/thyme/user/dropin.fnl:102")
  _G.assert((nil ~= replacement), "Missing argument replacement on fnl/thyme/user/dropin.fnl:102")
  _G.assert((nil ~= pattern), "Missing argument pattern on fnl/thyme/user/dropin.fnl:102")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin.fnl:102")
  return table.insert(self._commands, {pattern = pattern, replacement = replacement, lang = lang})
end
Dropin["enable-dropin-paren!"] = function(self)
  self["register!"](self, "^[[%[%(%{].*", "Fnl %0", {lang = "fennel"})
  local opts = Config["dropin-paren"]
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl)"
  local plug_map_complete = "<Plug>(thyme-dropin-complete-Fnl)"
  do
    local _22_ = opts["cmdline-key"]
    if (_22_ == false) then
    elseif (_22_ == "") then
    elseif (nil ~= _22_) then
      local key = _22_
      vim.api.nvim_set_keymap("c", plug_map_insert, "<C-BSlash>ev:lua.require('thyme.user.dropin').replace()<CR><CR>", {noremap = true})
      vim.api.nvim_set_keymap("c", key, plug_map_insert, {noremap = true})
    else
    end
  end
  local _24_ = opts["cmdline-completion-key"]
  if (_24_ == false) then
    return nil
  elseif (_24_ == "") then
    return nil
  elseif (nil ~= _24_) then
    local key = _24_
    vim.api.nvim_set_keymap("c", plug_map_complete, "<Cmd>lua require('thyme.user.dropin').complete()<CR>", {noremap = true})
    return vim.api.nvim_set_keymap("c", key, plug_map_complete, {noremap = true})
  else
    return nil
  end
end
local SingletonDropin = Dropin._new()
local function _26_(...)
  return SingletonDropin["register!"](SingletonDropin, ...)
end
local function _27_(...)
  return SingletonDropin["replace-cmdline!"](SingletonDropin, ...)
end
local function _28_(...)
  return SingletonDropin["complete-cmdline!"](SingletonDropin, ...)
end
local function _29_()
  return SingletonDropin["enable-dropin-paren!"](SingletonDropin)
end
return {register = _26_, replace = _27_, complete = _28_, ["enable-dropin-paren!"] = _29_}
