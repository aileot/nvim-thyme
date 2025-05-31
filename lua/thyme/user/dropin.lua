local Config = require("thyme.config")
local M = {}
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
local function replace_invalid_cmdline(old_cmdline, invalid_cmd, pattern, replacement)
  local prefix = old_cmdline:sub(1, (-1 - #invalid_cmd))
  local fallback_cmd = invalid_cmd:gsub(pattern, replacement)
  local new_cmdline = (prefix .. fallback_cmd)
  return new_cmdline
end
M.replace = function(pattern, replacement)
  local cmdtype = get_cmdtype()
  local old_cmdline = vim.fn.getcmdline()
  if (":" == cmdtype) then
    local _5_ = extract__3finvalid_cmd(old_cmdline)
    if (nil ~= _5_) then
      local invalid_cmd = _5_
      local new_cmdline = replace_invalid_cmdline(old_cmdline, invalid_cmd, pattern, replacement)
      local function _6_()
        return assert((1 == vim.fn.histadd(cmdtype, old_cmdline)), ("failed to add old command " .. old_cmdline))
      end
      vim.schedule(_6_)
      return new_cmdline
    else
      local _ = _5_
      return old_cmdline
    end
  else
    return old_cmdline
  end
end
M.complete = function(pattern, replacement)
  local cmdtype = get_cmdtype()
  local old_cmdline = vim.fn.getcmdline()
  local new_cmdline
  if (":" == cmdtype) then
    local _9_ = extract__3finvalid_cmd(old_cmdline)
    if (nil ~= _9_) then
      local invalid_cmd = _9_
      new_cmdline = replace_invalid_cmdline(old_cmdline, invalid_cmd, pattern, replacement)
    else
      local _ = _9_
      new_cmdline = old_cmdline
    end
  else
    new_cmdline = old_cmdline
  end
  local last_lz = vim.o.lazyredraw
  local last_wcm = vim.o.wildcharm
  local tmp_wcm = ""
  local right_keys
  do
    local _12_ = new_cmdline:find(old_cmdline, 1, true)
    if (_12_ == nil) then
      right_keys = ""
    elseif (nil ~= _12_) then
      local shift = _12_
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
M["enable-dropin-paren!"] = function()
  local opts = Config["dropin-paren"]
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl)"
  local plug_map_complete = "<Plug>(thyme-dropin-complete-Fnl)"
  do
    local _14_ = opts["cmdline-key"]
    if (_14_ == false) then
    elseif (_14_ == "") then
    elseif (nil ~= _14_) then
      local key = _14_
      vim.api.nvim_set_keymap("c", plug_map_insert, "<C-BSlash>ev:lua.require('thyme.user.dropin').replace('^[%[%(%{].*','Fnl %0')<CR><CR>", {noremap = true})
      vim.api.nvim_set_keymap("c", key, plug_map_insert, {noremap = true})
    else
    end
  end
  local _16_ = opts["cmdline-completion-key"]
  if (_16_ == false) then
    return nil
  elseif (_16_ == "") then
    return nil
  elseif (nil ~= _16_) then
    local key = _16_
    vim.api.nvim_set_keymap("c", plug_map_complete, "<Cmd>lua require('thyme.user.dropin').complete('^[%[%(%{].*','Fnl %0')<CR>", {noremap = true})
    return vim.api.nvim_set_keymap("c", key, plug_map_complete, {noremap = true})
  else
    return nil
  end
end
return M
