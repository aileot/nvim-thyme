local Config = require("thyme.config")
local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local DropinRegistry = require("thyme.user.dropin.registry")
local DropinCmdline = require("thyme.user.dropin.replacer.cmdline")
local M = {}
local function map_keys_in_cmdline_21()
  local opts = Config["dropin-paren"]
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl)"
  local plug_map_complete = "<Plug>(thyme-dropin-complete-Fnl)"
  do
    local _2_ = opts["cmdline-key"]
    if (_2_ == false) then
    elseif (_2_ == "") then
    elseif (nil ~= _2_) then
      local key = _2_
      vim.api.nvim_set_keymap("c", plug_map_insert, "<C-BSlash>ev:lua.require('thyme.user.dropin').cmdline.replace(getcmdline())<CR><CR>", {noremap = true})
      vim.api.nvim_set_keymap("c", key, plug_map_insert, {noremap = true})
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
M["enable-dropin-paren!"] = function()
  return map_keys_in_cmdline_21()
end
local registry = DropinRegistry.new()
registry["register!"](registry, "^[[%[%(%{].*", "Fnl %0")
M.registry = registry
local function _6_(...)
  if ((":" == vim.fn.getcmdtype()) or debug_3f) then
    local dropin = DropinCmdline.new(registry)
    return dropin["replace-cmdline!"](dropin, ...)
  else
    return ...
  end
end
local function _8_(...)
  if (":" == vim.fn.getcmdtype()) then
    local dropin = DropinCmdline.new(registry)
    return dropin["complete-cmdline!"](dropin, ...)
  else
    return ...
  end
end
M.cmdline = {replace = _6_, complete = _8_}
return M
