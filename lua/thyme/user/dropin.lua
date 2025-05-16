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
  local old_cmdline = vim.fn.getcmdline()
  local _7_ = extract__3finvalid_cmd(old_cmdline)
  if (nil ~= _7_) then
    local invalid_cmd = _7_
    local new_cmdline = replace_invalid_cmdline(old_cmdline, invalid_cmd, pattern, replacement)
    local last_wcm = vim.o.wildcharm
    local tmp_wcm = "\26"
    local right_keys
    do
      local _8_ = new_cmdline:find(old_cmdline, 1, true)
      if (_8_ == nil) then
        right_keys = ""
      elseif (nil ~= _8_) then
        local shift = _8_
        right_keys = string.rep("<Right>", (shift - 1))
      else
        right_keys = nil
      end
    end
    local keys = (vim.keycode((("<C-BSlash>e%q<CR>"):format(new_cmdline) .. right_keys)) .. tmp_wcm)
    vim.o.wcm = vim.fn.str2nr(tmp_wcm)
    vim.api.nvim_feedkeys(keys, "ni", false)
    vim.o.wcm = last_wcm
    return nil
  else
    return nil
  end
end
M["enable-dropin-paren!"] = function(opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/dropin.fnl:77")
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl)"
  local plug_map_complete = "<Plug>(thyme-dropin-complete-Fnl)"
  do
    local _11_ = opts["cmdline-key"]
    if (_11_ == false) then
    elseif (_11_ == "") then
    elseif (nil ~= _11_) then
      local key = _11_
      vim.api.nvim_set_keymap("c", plug_map_insert, "<C-BSlash>ev:lua.require('thyme.user.dropin').reserve('^[%[%(%{].*','Fnl %0')<CR><CR>", {noremap = true})
      vim.api.nvim_set_keymap("c", key, plug_map_insert, {noremap = true})
    else
    end
  end
  local _13_ = opts["cmdline-completion-key"]
  if (_13_ == false) then
    return nil
  elseif (_13_ == "") then
    return nil
  elseif (nil ~= _13_) then
    local key = _13_
    vim.api.nvim_set_keymap("c", plug_map_complete, "<Cmd>lua require('thyme.user.dropin').complete('^[%[%(%{].*','Fnl %0')<CR>", {noremap = true})
    return vim.api.nvim_set_keymap("c", key, plug_map_complete, {noremap = true})
  else
    return nil
  end
end
return M
