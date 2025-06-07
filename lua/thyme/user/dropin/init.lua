local Config = require("thyme.config")
local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local DropinRegistry = require("thyme.user.dropin.registry")
local DropinCmdline = require("thyme.user.dropin.replacer.cmdline")
local DropinCmdwin = require("thyme.user.dropin.replacer.cmdwin")
local M = {}
local function map_keys_in_cmdline_21()
  local opts = Config.dropin
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl-if-needed)"
  local plug_map_complete = "<Plug>(thyme-dropin-complete-with-Fnl-if-needed)"
  do
    local _2_ = opts["cmdline-key"]
    if (_2_ == false) then
    elseif (_2_ == "") then
    elseif (nil ~= _2_) then
      local key = _2_
      vim.api.nvim_set_keymap("c", plug_map_insert, "<C-BSlash>ev:lua.require('thyme.user.dropin').cmdline.replace(getcmdline())<CR>", {noremap = true})
      vim.api.nvim_set_keymap("c", key, (plug_map_insert .. "<CR>"), {noremap = true})
    else
    end
  end
  local _4_ = opts["cmdline-completion-key"]
  if (_4_ == false) then
    return nil
  elseif (_4_ == "") then
    return nil
  elseif (nil ~= _4_) then
    local key = _4_
    vim.api.nvim_set_keymap("c", plug_map_complete, "<Cmd>lua require('thyme.user.dropin').cmdline.complete(vim.fn.getcmdline())<CR>", {noremap = true})
    return vim.api.nvim_set_keymap("c", key, plug_map_complete, {noremap = true})
  else
    return nil
  end
end
local function map_keys_in_cmdwin_21(buf)
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl-if-needed)"
  vim.api.nvim_set_keymap("n", plug_map_insert, "<Cmd>lua require('thyme.user.dropin').cmdwin.replace(vim.fn.line('.'))<CR>", {noremap = true})
  vim.api.nvim_set_keymap("i", plug_map_insert, "<Cmd>lua require('thyme.user.dropin').cmdwin.replace(vim.fn.line('.'))<CR>", {noremap = true})
  local _6_ = Config.dropin.cmdwin["enter-key"]
  if (_6_ == false) then
    return nil
  elseif (_6_ == "") then
    return nil
  elseif (nil ~= _6_) then
    local key = _6_
    vim.api.nvim_buf_set_keymap(buf, "n", key, (plug_map_insert .. "<CR>"), {noremap = true, nowait = true})
    return vim.api.nvim_buf_set_keymap(buf, "i", key, (plug_map_insert .. "<CR>"), {noremap = true, nowait = true})
  else
    return nil
  end
end
M["enable-dropin-paren!"] = function()
  map_keys_in_cmdline_21()
  local group = vim.api.nvim_create_augroup("ThymeDropinCmdwin", {})
  local function _8_(_241)
    return map_keys_in_cmdwin_21(_241.buf)
  end
  return vim.api.nvim_create_autocmd("CmdWinEnter", {group = group, pattern = ":", callback = _8_})
end
local registry = DropinRegistry.new()
registry["register!"](registry, "^[[%[%(%{].*", "Fnl %0")
M.registry = registry
local function _9_(old_cmdline)
  local cmdtype = vim.fn.getcmdtype()
  if ((":" == cmdtype) or debug_3f) then
    local dropin = DropinCmdline.new(cmdtype, registry, old_cmdline)
    return dropin["replace-cmdline!"](dropin)
  else
    return old_cmdline
  end
end
local function _11_(old_cmdline)
  local cmdtype = vim.fn.getcmdtype()
  if (":" == cmdtype) then
    local dropin = DropinCmdline.new(cmdtype, registry, old_cmdline)
    return dropin["complete-cmdline!"](dropin)
  else
    return old_cmdline
  end
end
M.cmdline = {replace = _9_, complete = _11_}
local function _13_(row)
  local cmdtype = vim.fn.getcmdwintype()
  if ((":" == cmdtype) or debug_3f) then
    local dropin = DropinCmdwin.new(cmdtype, registry, row)
    return dropin["replace-cmdline!"](dropin)
  else
    return nil
  end
end
M.cmdwin = {replace = _13_}
return M
