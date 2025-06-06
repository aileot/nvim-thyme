local _local_1_ = require("thyme.loader.runtime-module")
local search_fnl_module_on_rtp_21 = _local_1_["search-fnl-module-on-rtp!"]
local M
local function _2_(...)
  return require("thyme.wrapper.fennel").view(...)
end
local function _3_(...)
  return require("thyme.wrapper.fennel").eval(...)
end
local function _4_(...)
  return require("thyme.wrapper.fennel")["compile-string"](...)
end
local function _5_(...)
  local key
  if select(3, ...) then
    key = "compile-file!"
  else
    key = "compile-file"
  end
  return require("thyme.wrapper.fennel")[key](...)
end
local function _7_(...)
  return require("thyme.wrapper.fennel")["compile-file"](...)
end
local function _8_(...)
  return require("thyme.wrapper.fennel")["compile-file!"](...)
end
local function _9_(...)
  return require("thyme.wrapper.fennel")["compile-buf"](...)
end
local function _10_(...)
  return require("thyme.wrapper.fennel").macrodebug(...)
end
local function _11_(...)
  return require("thyme.user.command.cache").open(...)
end
local function _12_(...)
  return require("thyme.user.command.cache").clear(...)
end
M = {loader = search_fnl_module_on_rtp_21, fennel = {view = _2_, eval = _3_, ["compile-string"] = _4_, compile_file = _5_, ["compile-file"] = _7_, ["compile-file!"] = _8_, ["compile-buf"] = _9_, macrodebug = _10_}, cache = {open = _11_, clear = _12_}}
local has_setup_3f = false
M.setup = function(_3fopts)
  assert(((nil == _3fopts) or (nil == next(_3fopts)) or (_3fopts == M)), "Please call `thyme.setup` without any args, or with an empty table.")
  if (not has_setup_3f or ("1" == vim.env.THYME_DEBUG)) then
    local watch = require("thyme.user.watch")
    local keymap = require("thyme.user.keymap")
    local command = require("thyme.user.command")
    local dropin = require("thyme.user.dropin")
    watch["watch-files!"]()
    keymap["define-keymaps!"]()
    command["define-commands!"]()
    dropin["enable-dropin-paren!"]()
    has_setup_3f = true
    return nil
  else
    return nil
  end
end
local function propagate_underscored_keys_21(tbl, key)
  local val = tbl[key]
  if key:find("[^-!]") then
    local new_key = key:gsub("!", ""):gsub("%-", "_")
    if (nil == tbl[new_key]) then
      tbl[new_key] = val
    else
    end
  else
  end
  local _16_ = type(val)
  if (_16_ == "table") then
    for k in pairs(val) do
      propagate_underscored_keys_21(val, k)
    end
    return nil
  else
    return nil
  end
end
for k in pairs(M) do
  propagate_underscored_keys_21(M, k)
end
return M
