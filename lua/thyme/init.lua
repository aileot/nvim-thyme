local _local_1_ = require("thyme.searcher.module")
local search_fnl_module_on_rtp_21 = _local_1_["search-fnl-module-on-rtp!"]
local M
local function _2_(...)
  return require("thyme.wrapper.fennel").view(...)
end
local function _3_(...)
  return require("thyme.wrapper.fennel").eval(...)
end
local function _4_(...)
  local key
  if select(3, ...) then
    key = "compile-file!"
  else
    key = "compile-file"
  end
  return require("thyme.wrapper.fennel")[key](...)
end
local function _6_(...)
  return require("thyme.wrapper.fennel")["compile-file"](...)
end
local function _7_(...)
  return require("thyme.wrapper.fennel")["compile-file!"](...)
end
local function _8_(...)
  return require("thyme.wrapper.fennel")["compile-string"](...)
end
local function _9_(...)
  return require("thyme.wrapper.fennel").macrodebug(...)
end
local function _10_(...)
  return require("thyme.user.check")["check-to-update!"](...)
end
local function _11_(...)
  return require("thyme.user.watch")["watch-to-update!"](...)
end
local function _12_(...)
  return require("thyme.user.keymaps")["define-keymaps!"](...)
end
local function _13_(...)
  return require("thyme.user.commands")["define-commands!"](...)
end
M = {loader = search_fnl_module_on_rtp_21, view = _2_, eval = _3_, compile_file = _4_, ["compile-file"] = _6_, ["compile-file!"] = _7_, ["compile-string"] = _8_, macrodebug = _9_, ["check-file!"] = _10_, ["watch-files!"] = _11_, ["define-keymaps!"] = _12_, ["define-commands!"] = _13_}
for k, v in pairs(M) do
  if k:find("[^-!]") then
    local new_key = k:gsub("!", ""):gsub("%-", "_")
    if (nil == M[new_key]) then
      M[new_key] = v
    else
    end
  else
  end
end
return M
