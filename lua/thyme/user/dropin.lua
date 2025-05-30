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
  _G.assert((nil ~= invalid_cmd), "Missing argument invalid-cmd on fnl/thyme/user/dropin.fnl:34")
  _G.assert((nil ~= old_cmdline), "Missing argument old-cmdline on fnl/thyme/user/dropin.fnl:34")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin.fnl:34")
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd
  do
    local new_cmd = invalid_cmd
    for _, _5_ in ipairs(self._commands) do
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
Dropin["replace-cmdline!"] = function(self)
  local cmdtype = get_cmdtype()
  local old_cmdline = vim.fn.getcmdline()
  local _7_
  do
    local _6_
    if (":" == cmdtype) then
      _6_ = extract__3finvalid_cmd(old_cmdline)
    else
      _6_ = nil
    end
    if (nil ~= _6_) then
      local invalid_cmd = _6_
      local new_cmdline = self["_replace-invalid-cmdline"](self, old_cmdline, invalid_cmd)
      local function _11_()
        return assert((1 == vim.fn.histadd(cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
      end
      vim.schedule(_11_)
      _7_ = new_cmdline
    else
      _7_ = nil
    end
  end
  return (_7_ or old_cmdline)
end
Dropin["complete-cmdline!"] = function(self)
  local cmdtype = get_cmdtype()
  local old_cmdline = vim.fn.getcmdline()
  local new_cmdline
  local _14_
  do
    local _13_
    if (":" == cmdtype) then
      _13_ = extract__3finvalid_cmd(old_cmdline)
    else
      _13_ = nil
    end
    if (nil ~= _13_) then
      local invalid_cmd = _13_
      _14_ = self["_replace-invalid-cmdline"](self, old_cmdline, invalid_cmd)
    else
      _14_ = nil
    end
  end
  new_cmdline = (_14_ or old_cmdline)
  local last_lz = vim.o.lazyredraw
  local last_wcm = vim.o.wildcharm
  local tmp_wcm = ""
  local right_keys
  do
    local _18_ = new_cmdline:find(old_cmdline, 1, true)
    if (_18_ == nil) then
      right_keys = ""
    elseif (nil ~= _18_) then
      local shift = _18_
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
Dropin["register!"] = function(self, pattern, replacement)
  _G.assert((nil ~= replacement), "Missing argument replacement on fnl/thyme/user/dropin.fnl:100")
  _G.assert((nil ~= pattern), "Missing argument pattern on fnl/thyme/user/dropin.fnl:100")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin.fnl:100")
  return table.insert(self._commands, {pattern = pattern, replacement = replacement})
end
Dropin["enable-dropin-paren!"] = function(self)
  self["register!"](self, "^[[%[%(%{].*", "Fnl %0")
  local opts = Config["dropin-paren"]
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl)"
  local plug_map_complete = "<Plug>(thyme-dropin-complete-Fnl)"
  do
    local _20_ = opts["cmdline-key"]
    if (_20_ == false) then
    elseif (_20_ == "") then
    elseif (nil ~= _20_) then
      local key = _20_
      vim.api.nvim_set_keymap("c", plug_map_insert, "<C-BSlash>ev:lua.require('thyme.user.dropin').replace()<CR><CR>", {noremap = true})
      vim.api.nvim_set_keymap("c", key, plug_map_insert, {noremap = true})
    else
    end
  end
  local _22_ = opts["cmdline-completion-key"]
  if (_22_ == false) then
    return nil
  elseif (_22_ == "") then
    return nil
  elseif (nil ~= _22_) then
    local key = _22_
    vim.api.nvim_set_keymap("c", plug_map_complete, "<Cmd>lua require('thyme.user.dropin').complete()<CR>", {noremap = true})
    return vim.api.nvim_set_keymap("c", key, plug_map_complete, {noremap = true})
  else
    return nil
  end
end
local SingletonDropin = Dropin._new()
local function _24_(...)
  return SingletonDropin["register!"](SingletonDropin, ...)
end
local function _25_(...)
  return SingletonDropin["replace-cmdline!"](SingletonDropin, ...)
end
local function _26_(...)
  return SingletonDropin["complete-cmdline!"](SingletonDropin, ...)
end
local function _27_()
  return SingletonDropin["enable-dropin-paren!"](SingletonDropin)
end
return {register = _24_, replace = _25_, complete = _26_, ["enable-dropin-paren!"] = _27_}
