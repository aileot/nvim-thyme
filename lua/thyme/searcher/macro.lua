local BackupManager = require("thyme.utils.backup-manager")
local MacroBackupManager = BackupManager.new("macro-rollback")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local _local_2_ = require("thyme.module-map.callstack")
local pcall_with_logger_21 = _local_2_["pcall-with-logger!"]
local is_logged_3f = _local_2_["is-logged?"]
local log_again_21 = _local_2_["log-again!"]
local cache = {["macro-loaded"] = {}}
local function macro_module__3e_3fchunk(module_name, fnl_path)
  local fennel = require("fennel")
  local _let_3_ = require("thyme.config")
  local get_config = _let_3_["get-config"]
  local config = get_config()
  local compiler_options = config["compiler-options"]
  local _3fenv = compiler_options.env
  compiler_options.env = "_COMPILER"
  local _4_, _5_ = pcall_with_logger_21(fennel.eval, fnl_path, nil, compiler_options, module_name)
  if ((_4_ == true) and (nil ~= _5_)) then
    local result = _5_
    local backup_path = MacroBackupManager["module-name->?current-backup-path"](MacroBackupManager, module_name)
    if ((fnl_path ~= backup_path) and MacroBackupManager["should-update-backup?"](MacroBackupManager, module_name, read_file(fnl_path))) then
      MacroBackupManager["create-module-backup!"](MacroBackupManager, module_name, fnl_path)
    else
    end
    compiler_options.env = _3fenv
    local function _7_()
      return result
    end
    return _7_
  elseif (true and (nil ~= _5_)) then
    local _ = _4_
    local msg = _5_
    local msg_prefix = ("\nthyme-macro-searcher: %s is found for the module %s, but failed to evaluate it in a compiler environment\n\t"):format(fnl_path, module_name)
    compiler_options.env = _3fenv
    return nil, (msg_prefix .. msg)
  else
    return nil
  end
end
local function search_fnl_macro_on_rtp_21(module_name)
  local fennel = require("fennel")
  local _9_, _10_ = nil, nil
  do
    local _11_, _12_ = fennel["search-module"](module_name, fennel["macro-path"])
    if (nil ~= _11_) then
      local fnl_path = _11_
      _9_, _10_ = macro_module__3e_3fchunk(module_name, fnl_path)
    elseif (true and (nil ~= _12_)) then
      local _ = _11_
      local msg = _12_
      _9_, _10_ = nil, ("thyme-macro-searcher: " .. msg)
    else
      _9_, _10_ = nil
    end
  end
  if (nil ~= _9_) then
    local chunk = _9_
    return chunk
  elseif (true and (nil ~= _10_)) then
    local _ = _9_
    local error_msg = _10_
    local backup_path = MacroBackupManager["module-name->?current-backup-path"](MacroBackupManager, module_name)
    local _let_14_ = require("thyme.config")
    local get_config = _let_14_["get-config"]
    local config = get_config()
    local rollback_3f = config.rollback
    if (rollback_3f and file_readable_3f(backup_path)) then
      local _15_, _16_ = macro_module__3e_3fchunk(module_name, backup_path)
      if (nil ~= _15_) then
        local chunk = _15_
        local msg = ("thyme-macro-rollback-loader: temporarily restore backup for the module %s due to the following error: %s"):format(module_name, error_msg)
        vim.notify_once(msg, vim.log.levels.WARN)
        return chunk
      elseif (true and (nil ~= _16_)) then
        local _0 = _15_
        local msg = _16_
        return nil, msg
      else
        return nil
      end
    else
      return nil, error_msg
    end
  else
    return nil
  end
end
local function overwrite_metatable_21(original_table, cache_table)
  do
    local _20_ = getmetatable(original_table)
    if (nil ~= _20_) then
      local mt = _20_
      setmetatable(cache_table, mt)
    else
    end
  end
  local function _22_(self, module_name, val)
    if is_logged_3f(module_name) then
      rawset(self, module_name, nil)
      cache_table[module_name] = val
      return nil
    else
      return rawset(self, module_name, val)
    end
  end
  local function _24_(_, module_name)
    local _25_ = cache_table[module_name]
    if (nil ~= _25_) then
      local cached = _25_
      log_again_21(module_name)
      return cached
    else
      return nil
    end
  end
  return setmetatable(original_table, {__newindex = _22_, __index = _24_})
end
local function initialize_macro_searcher_on_rtp_21(fennel)
  table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)
  local function _27_(...)
    local _28_, _29_ = search_fnl_macro_on_rtp_21(...)
    if (nil ~= _28_) then
      local chunk = _28_
      return chunk
    elseif (true and (nil ~= _29_)) then
      local _ = _28_
      local msg = _29_
      return msg
    else
      return nil
    end
  end
  table.insert(package.loaders, _27_)
  return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"])
end
return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21}
