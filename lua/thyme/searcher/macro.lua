

 local ModuleMap = require("thyme.module-map.callstack")

 local BackupManager = require("thyme.backup-manager")
 local MacroBackupManager = BackupManager.new("macro")

 local _local_1_ = require("thyme.utils.fs") local file_readable_3f = _local_1_["file-readable?"]

 local cache = {["macro-loaded"] = {}}

 local function macro_module__3e_3fchunk(module_name, fnl_path)
 local fennel = require("fennel")
 local _let_2_ = require("thyme.config") local get_main_config = _let_2_["get-main-config"]
 local config = get_main_config()
 local compiler_options = config["compiler-options"]
 local _3fenv = compiler_options.env compiler_options.env = "_COMPILER"







 local _3_, _4_ = ModuleMap["pcall-with-logger!"](fennel.eval, fnl_path, nil, compiler_options, module_name) if ((_3_ == true) and (nil ~= _4_)) then local result = _4_ local backup_path = MacroBackupManager["module-name->backup-path"](MacroBackupManager, module_name)



 compiler_options.env = _3fenv

 if not (fnl_path == backup_path) then MacroBackupManager["backup-module!"](MacroBackupManager, module_name, fnl_path) else end

 local function _6_() return result end return _6_ elseif (true and (nil ~= _4_)) then local _ = _3_ local msg = _4_
 local msg_prefix = ("\nthyme-macro-searcher: %s is found for the macro module %s, but failed to evaluate it in a compiler environment\n\t"):format(fnl_path, module_name)


 compiler_options.env = _3fenv





 return nil, (msg_prefix .. msg) else return nil end end

 local function search_fnl_macro_on_rtp_21(module_name)





 local fennel = require("fennel")
 local _8_, _9_ = nil, nil do local _10_, _11_ = fennel["search-module"](module_name, fennel["macro-path"]) if (nil ~= _10_) then local fnl_path = _10_
 _8_, _9_ = macro_module__3e_3fchunk(module_name, fnl_path) elseif (true and (nil ~= _11_)) then local _ = _10_ local msg = _11_
 _8_, _9_ = nil, ("thyme-macro-searcher: " .. msg) else _8_, _9_ = nil end end if (nil ~= _8_) then local chunk = _8_
 return chunk elseif (true and (nil ~= _9_)) then local _ = _8_ local error_msg = _9_ local backup_path = MacroBackupManager["module-name->backup-path"](MacroBackupManager, module_name)


 local _let_13_ = require("thyme.config") local get_main_config = _let_13_["get-main-config"]
 local config = get_main_config()
 local rollback_3f = config.rollback
 if (rollback_3f and file_readable_3f(backup_path)) then
 local _14_, _15_ = macro_module__3e_3fchunk(module_name, backup_path) if (nil ~= _14_) then local chunk = _14_



 local msg = ("thyme-backup-loader: temporarily restore backup for the module %s due to the following error: %s"):format(module_name, error_msg)

 vim.notify_once(msg, vim.log.levels.WARN)
 return chunk elseif (true and (nil ~= _15_)) then local _0 = _14_ local msg = _15_

 return nil, msg else return nil end else
 return nil, error_msg end else return nil end end

 local function overwrite_metatable_21(original_table, cache_table)
 do local _19_ = getmetatable(original_table) if (nil ~= _19_) then local mt = _19_
 setmetatable(cache_table, mt) else end end

 local function _21_(self, module_name, val)





 if ModuleMap["is-logged?"](module_name) then

 rawset(self, module_name, nil)
 do end (cache_table)[module_name] = val return nil else
 return rawset(self, module_name, val) end end
 local function _23_(_, module_name)

 local _24_ = cache_table[module_name] if (nil ~= _24_) then local cached = _24_

 ModuleMap["log-again!"](module_name)
 return cached else return nil end end return setmetatable(original_table, {__newindex = _21_, __index = _23_}) end

 local function initialize_macro_searcher_on_rtp_21(fennel)




 table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)



 local function _26_(...)
 local _27_, _28_ = search_fnl_macro_on_rtp_21(...) if (nil ~= _27_) then local chunk = _27_
 return chunk elseif (true and (nil ~= _28_)) then local _ = _27_ local msg = _28_
 return msg else return nil end end table.insert(package.loaders, _26_)
 return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"]) end

 return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21}
