local M = {}
local function extract__3finvalid_cmd(cmdline)
  local _1_, _2_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if (_1_ == true) then
    return cmdline
  elseif ((_1_ == false) and (nil ~= _2_)) then
    local msg = _2_
    local expected_error_msg_prefix = "Parsing command%-line: E492: Not an editor command: (.*)"
    return msg:match(expected_error_msg_prefix)
  else
    return nil
  end
end
M.reserve = function(pattern, replacement)
  local old_cmdline = vim.fn.getcmdline()
  local _4_ = extract__3finvalid_cmd(old_cmdline)
  if (nil ~= _4_) then
    local invalid_cmd = _4_
    local cmdtype = vim.fn.getcmdtype()
    local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
    local fallback_cmd = invalid_cmd:gsub(pattern, replacement)
    local new_cmdline = (prefix .. fallback_cmd)
    local function _5_()
      return assert((1 == vim.fn.histadd(cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
    end
    vim.schedule(_5_)
    return new_cmdline
  else
    local _ = _4_
    return old_cmdline
  end
end
M["enable-dropin-paren!"] = function(opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/dropin.fnl:34")
  for _, key in ipairs(opts["cmdline-maps"]) do
    vim.api.nvim_set_keymap("c", key, "<C-BSlash>ev:lua.require('thyme.user.dropin').reserve('[%[%(%{]].*','Fnl %0')<CR><CR>", {noremap = true})
  end
  local _7_ = opts["cmdline-completion-key"]
  if (_7_ == false) then
    return nil
  elseif (nil ~= _7_) then
    local key = _7_
    return vim.api.nvim_set_keymap("c", key, "<C-BSlash>ev:lua.require('thyme.user.dropin').complete('[%[%(%{]].*','Fnl %0','lua')<CR><CR>", {noremap = true})
  else
    return nil
  end
end
return M
