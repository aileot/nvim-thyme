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
local function replace_invalid_cmdline(old_cmdline, invalid_cmd, pattern, replacement)
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd = invalid_cmd:gsub(pattern, replacement)
  local new_cmdline = (prefix .. fallback_cmd)
  return new_cmdline
end
M.reserve = function(pattern, replacement)
  local old_cmdline = vim.fn.getcmdline()
  local _4_ = extract__3finvalid_cmd(old_cmdline)
  if (nil ~= _4_) then
    local invalid_cmd = _4_
    local cmdtype = vim.fn.getcmdtype()
    local new_cmdline = replace_invalid_cmdline(old_cmdline, invalid_cmd, pattern, replacement)
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
M.complete = function(pattern, replacement)
  local new_cmdline = M.reserve(pattern, replacement)
  local last_wcm = vim.o.wildcharm
  local tmp_wcm = "\26"
  local keys = (vim.keycode(("<C-BSlash>e%q<CR>"):format(new_cmdline)) .. tmp_wcm)
  vim.o.wcm = vim.fn.str2nr(tmp_wcm)
  vim.api.nvim_feedkeys(keys, "ni", false)
  vim.o.wcm = last_wcm
  return nil
end
M["enable-dropin-paren!"] = function(opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/dropin.fnl:65")
  do
    local _7_ = opts["cmdline-key"]
    if (_7_ == false) then
    elseif (nil ~= _7_) then
      local key = _7_
      vim.api.nvim_set_keymap("c", key, "<C-BSlash>ev:lua.require('thyme.user.dropin').reserve('^[%[%(%{].*','Fnl %0')<CR><CR>", {noremap = true})
    else
    end
  end
  local _9_ = opts["cmdline-completion-key"]
  if (_9_ == false) then
    return nil
  elseif (nil ~= _9_) then
    local key = _9_
    return vim.api.nvim_set_keymap("c", key, "<Cmd>lua require('thyme.user.dropin').complete('^[%[%(%{].*','Fnl %0')<CR>", {noremap = true})
  else
    return nil
  end
end
return M
