local RollbackManager = require("thyme.rollback")
local MacroRollbackManager = RollbackManager.new("macro", ".fnl")
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
    local backup_handler = MacroRollbackManager:backupHandlerOf(module_name)
    local backup_path = backup_handler["module-name->active-backup-path"](backup_handler)
    if ((fnl_path ~= backup_path) and backup_handler["should-update-backup?"](backup_handler, read_file(fnl_path))) then
      backup_handler["create-module-backup!"](backup_handler, fnl_path)
      backup_handler["cleanup-old-backups!"](backup_handler)
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
  MacroRollbackManager["inject-mounted-backup-searcher!"](MacroRollbackManager, fennel["macro-searchers"])
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
    local backup_handler = MacroRollbackManager:backupHandlerOf(module_name)
    local backup_path = backup_handler["module-name->active-backup-path"](backup_handler)
    local _let_14_ = require("thyme.config")
    local get_config = _let_14_["get-config"]
    local config = get_config()
    local _15_ = config["?error-msg"]
    if (nil ~= _15_) then
      local msg = _15_
      return nil, msg
    else
      local _0 = _15_
      local max_rollbacks = config["max-rollbacks"]
      local rollback_enabled_3f = (0 < max_rollbacks)
      if (rollback_enabled_3f and file_readable_3f(backup_path)) then
        local _16_, _17_ = macro_module__3e_3fchunk(module_name, backup_path)
        if (nil ~= _16_) then
          local chunk = _16_
          local msg = ("thyme-macro-rollback-loader: temporarily restore backup for the module %s (created at %s) due to the following error: %s\nHINT: You can reduce its annoying errors during repairing the module running `:ThymeRollbackMount` to keep the active backup in the next nvim session.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["module-name->active-backup-birthtime"](backup_handler), error_msg)
          vim.notify_once(msg, vim.log.levels.WARN)
          return chunk
        elseif (true and (nil ~= _17_)) then
          local _1 = _16_
          local msg = _17_
          return nil, msg
        else
          return nil
        end
      else
        return nil, error_msg
      end
    end
  else
    return nil
  end
end
local function overwrite_metatable_21(original_table, cache_table)
  do
    local _22_ = getmetatable(original_table)
    if (nil ~= _22_) then
      local mt = _22_
      setmetatable(cache_table, mt)
    else
    end
  end
  local function _24_(self, module_name, val)
    if is_logged_3f(module_name) then
      rawset(self, module_name, nil)
      cache_table[module_name] = val
      return nil
    else
      return rawset(self, module_name, val)
    end
  end
  local function _26_(_, module_name)
    local _27_ = cache_table[module_name]
    if (nil ~= _27_) then
      local cached = _27_
      log_again_21(module_name)
      return cached
    else
      return nil
    end
  end
  return setmetatable(original_table, {__newindex = _24_, __index = _26_})
end
local function initialize_macro_searcher_on_rtp_21(fennel)
  table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)
  local function _29_(...)
    local _30_, _31_ = search_fnl_macro_on_rtp_21(...)
    if (nil ~= _30_) then
      local chunk = _30_
      return chunk
    elseif (true and (nil ~= _31_)) then
      local _ = _30_
      local msg = _31_
      return msg
    else
      return nil
    end
  end
  table.insert(package.loaders, _29_)
  return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"])
end
return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21}
