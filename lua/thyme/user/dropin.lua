local M = {}
M.reserve = function(pattern, replacement)
  local cmdtype = vim.fn.getcmdtype()
  local old_cmdline = vim.fn.getcmdline()
  local _1_, _2_ = pcall(vim.api.nvim_parse_cmd, old_cmdline, {})
  if (_1_ == true) then
    return old_cmdline
  elseif ((_1_ == false) and (nil ~= _2_)) then
    local msg = _2_
    local expected_error_msg_prefix = "Parsing command%-line: E492: Not an editor command: (.*)"
    local _3_ = msg:match(expected_error_msg_prefix)
    if (nil ~= _3_) then
      local invalid_cmd = _3_
      local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
      local fallback_cmd = invalid_cmd:gsub(pattern, replacement)
      local new_cmdline = (prefix .. fallback_cmd)
      local function _4_()
        return assert((1 == vim.fn.histadd(cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
      end
      vim.schedule(_4_)
      return new_cmdline
    else
      local _ = _3_
      return old_cmdline
    end
  else
    return nil
  end
end
M.complete = function(pattern, replacement, completion_type)
  return "Complete cmdline pretending `replacement` to replace invalid cmdline when\n`pattern` is detected with E492.\n@param pattern string string Lua patterns to be support dropin fallback.\n@param replacement string The dropin command\n@param completion-type string The completion type"
end
M["enable-dropin-paren!"] = function(opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/dropin.fnl:40")
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
