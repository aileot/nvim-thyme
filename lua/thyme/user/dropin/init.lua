local Config = require("thyme.lazy-config")
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
    local _2_ = opts.cmdline["enter-key"]
    if (_2_ == false) then
    elseif (_2_ == "") then
    elseif (nil ~= _2_) then
      local key = _2_
      local function _3_()
        return M.cmdline.replace(vim.fn.getcmdline())
      end
      vim.api.nvim_set_keymap("c", plug_map_insert, "", {noremap = true, expr = true, replace_keycodes = true, callback = _3_})
      vim.api.nvim_set_keymap("c", key, (plug_map_insert .. "<CR>"), {noremap = true})
    else
    end
  end
  local _5_ = opts.cmdline["completion-key"]
  if (_5_ == false) then
    return nil
  elseif (_5_ == "") then
    return nil
  elseif (nil ~= _5_) then
    local key = _5_
    local function _6_()
      return M.cmdline.complete(vim.fn.getcmdline())
    end
    vim.api.nvim_set_keymap("c", plug_map_complete, "", {noremap = true, expr = true, replace_keycodes = true, callback = _6_})
    return vim.api.nvim_set_keymap("c", key, plug_map_complete, {noremap = true})
  else
    return nil
  end
end
local function map_keys_in_cmdwin_21(buf)
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl-if-needed)"
  local function _8_()
    return M.cmdwin.replace(vim.fn.line("."))
  end
  vim.api.nvim_set_keymap("n", plug_map_insert, "", {noremap = true, callback = _8_})
  local function _9_()
    return M.cmdwin.replace(vim.fn.line("."))
  end
  vim.api.nvim_set_keymap("i", plug_map_insert, "", {noremap = true, callback = _9_})
  local _10_ = Config.dropin.cmdwin["enter-key"]
  if (_10_ == false) then
    return nil
  elseif (_10_ == "") then
    return nil
  elseif (nil ~= _10_) then
    local key = _10_
    vim.api.nvim_buf_set_keymap(buf, "n", key, (plug_map_insert .. "<CR>"), {noremap = true, nowait = true})
    return vim.api.nvim_buf_set_keymap(buf, "i", key, (plug_map_insert .. "<CR>"), {noremap = true, nowait = true})
  else
    return nil
  end
end
M["enable-dropin-paren!"] = function()
  map_keys_in_cmdline_21()
  local group = vim.api.nvim_create_augroup("ThymeDropinCmdwin", {})
  local function _12_(_241)
    return map_keys_in_cmdwin_21(_241.buf)
  end
  return vim.api.nvim_create_autocmd("CmdWinEnter", {group = group, pattern = ":", callback = _12_})
end
local registry = DropinRegistry.new()
registry["register!"](registry, "^(.-)[fF][nN][lL]?(.*)", "%1Fnl%2")
registry["register!"](registry, "^(.-)([[%[%(%{].*)", "%1Fnl %2")
M.registry = registry
local function _13_(old_cmdline)
  local cmdtype = vim.fn.getcmdtype()
  if ((":" == cmdtype) or debug_3f) then
    local dropin = DropinCmdline.new(cmdtype, registry, old_cmdline)
    return dropin["replace-cmdline!"](dropin)
  else
    return nil
  end
end
local function _15_(old_cmdline)
  local cmdtype = vim.fn.getcmdtype()
  if (":" == cmdtype) then
    local dropin = DropinCmdline.new(cmdtype, registry, old_cmdline)
    return dropin["complete-cmdline!"](dropin)
  else
    return nil
  end
end
M.cmdline = {replace = _13_, complete = _15_}
local function _17_(row)
  local cmdtype = vim.fn.getcmdwintype()
  if ((":" == cmdtype) or debug_3f) then
    local dropin = DropinCmdwin.new(cmdtype, registry, row)
    return dropin["replace-cmdline!"](dropin)
  else
    return nil
  end
end
M.cmdwin = {replace = _17_}
return M
