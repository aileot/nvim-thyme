






 local _local_1_ = require("thyme.searcher.module") local search_fnl_module_on_rtp_21 = _local_1_["search-fnl-module-on-rtp!"]

 local M
 local function _2_(...) return require("thyme.wrapper.fennel").view(...) end
 local function _3_(...) return require("thyme.wrapper.fennel").eval(...) end
 local function _4_(...) return require("thyme.wrapper.fennel")["compile-file!"](...) end

 local function _5_(...) return require("thyme.wrapper.fennel")["compile-string"](...) end

 local function _6_(...) return require("thyme.wrapper.fennel").macrodebug(...) end
 local function _7_(...) return require("thyme.user.check")["check-to-update!"](...) end

 local function _8_(...) return require("thyme.user.watch")["watch-to-update!"](...) end

 local function _9_(...) return require("thyme.user.keymaps")["define-keymaps!"](...) end

 local function _10_(...) return require("thyme.user.commands")["define-commands!"](...) end M = {loader = search_fnl_module_on_rtp_21, view = _2_, eval = _3_, ["compile-file!"] = _4_, ["compile-string"] = _5_, macrodebug = _6_, ["check-file!"] = _7_, ["watch-files!"] = _8_, ["define-keymaps!"] = _9_, ["define-commands!"] = _10_}


 for k, v in pairs(M) do


 if k:find("[^-!]") then
 local new_key = k:gsub("!", ""):gsub("%-", "_")


 do end (M)[new_key] = v else end end

 return M
