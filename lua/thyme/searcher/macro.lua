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
  local Config = require("thyme.config")
  local compiler_options = Config["compiler-options"]
  local _3fenv = compiler_options.env
  compiler_options.env = "_COMPILER"
  local _3_, _4_ = pcall_with_logger_21(fennel.eval, fnl_path, nil, compiler_options, module_name)
  if ((_3_ == true) and (nil ~= _4_)) then
    local result = _4_
    local backup_handler = MacroRollbackManager:backupHandlerOf(module_name)
    local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
    if ((fnl_path ~= backup_path) and backup_handler["should-update-backup?"](backup_handler, read_file(fnl_path))) then
      backup_handler["write-backup!"](backup_handler, fnl_path)
      backup_handler["cleanup-old-backups!"](backup_handler)
    else
    end
    compiler_options.env = _3fenv
    local function _6_()
      return result
    end
    return _6_
  elseif (true and (nil ~= _4_)) then
    local _ = _3_
    local msg = _4_
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
  local _8_, _9_ = nil, nil
  do
    local _10_, _11_ = fennel["search-module"](module_name, fennel["macro-path"])
    if (nil ~= _10_) then
      local fnl_path = _10_
      _8_, _9_ = macro_module__3e_3fchunk(module_name, fnl_path)
    elseif (true and (nil ~= _11_)) then
      local _ = _10_
      local msg = _11_
      _8_, _9_ = nil, ("thyme-macro-searcher: " .. msg)
    else
      _8_, _9_ = nil
    end
  end
  if (nil ~= _8_) then
    local chunk = _8_
    return chunk
  elseif (true and (nil ~= _9_)) then
    local _ = _8_
    local error_msg = _9_
    local backup_handler = MacroRollbackManager:backupHandlerOf(module_name)
    local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
    local Config = require("thyme.config")
    local _13_ = Config["?error-msg"]
    if (nil ~= _13_) then
      local msg = _13_
      return nil, msg
    else
      local _0 = _13_
      local max_rollbacks = Config["max-rollbacks"]
      local rollback_enabled_3f = (0 < max_rollbacks)
      if (rollback_enabled_3f and file_readable_3f(backup_path)) then
        local _14_, _15_ = macro_module__3e_3fchunk(module_name, backup_path)
        if (nil ~= _14_) then
          local chunk = _14_
          local msg = ("thyme-macro-rollback-loader: temporarily restore backup for the module %s (created at %s) due to the following error: %s\nHINT: You can reduce its annoying errors during repairing the module running `:ThymeRollbackMount` to keep the active backup in the next nvim session.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler), error_msg)
          vim.notify_once(msg, vim.log.levels.WARN)
          return chunk
        elseif (true and (nil ~= _15_)) then
          local _1 = _14_
          local msg = _15_
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
