local Config = require("thyme.config")
local DropinRegistry = require("thyme.user.dropin.registry")
local DropinCmdline = require("thyme.user.dropin.replacer.cmdline")
local M = {}
M["enable-dropin-paren!"] = function()
  local opts = Config["dropin-paren"]
  local plug_map_insert = "<Plug>(thyme-dropin-insert-Fnl)"
  local plug_map_complete = "<Plug>(thyme-dropin-complete-Fnl)"
  do
    local _1_ = opts["cmdline-key"]
    if (_1_ == false) then
    elseif (_1_ == "") then
    elseif (nil ~= _1_) then
      local key = _1_
      vim.api.nvim_set_keymap("c", plug_map_insert, "<C-BSlash>ev:lua.require('thyme.user.dropin').cmdline.replace(getcmdline())<CR><CR>", {noremap = true})
      vim.api.nvim_set_keymap("c", key, plug_map_insert, {noremap = true})
    else
    end
  end
  local _3_ = opts["cmdline-completion-key"]
  if (_3_ == false) then
    return nil
  elseif (_3_ == "") then
    return nil
  elseif (nil ~= _3_) then
    local key = _3_
    vim.api.nvim_set_keymap("c", plug_map_complete, "<Cmd>lua require('thyme.user.dropin').cmdline.complete()<CR>", {noremap = true})
    return vim.api.nvim_set_keymap("c", key, plug_map_complete, {noremap = true})
  else
    return nil
  end
end
local registry = DropinRegistry.new()
registry["register!"](registry, "^[[%[%(%{].*", "Fnl %0")
M.registry = registry
local function _5_(...)
  if (":" == vim.fn.getcmdtype()) then
    local dropin = DropinCmdline.new(registry)
    return dropin["replace-cmdline!"](dropin, ...)
  else
    return nil
  end
end
local function _7_(...)
  if (":" == vim.fn.getcmdtype()) then
    local dropin = DropinCmdline.new(registry)
    return dropin["complete-cmdline!"](dropin, ...)
  else
    return nil
  end
end
M.cmdline = {replace = _5_, complete = _7_}
return M
