local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local _local_2_ = require("thyme.module-map.callstack")
local pcall_with_logger_21 = _local_2_["pcall-with-logger!"]
local is_logged_3f = _local_2_["is-logged?"]
local log_again_21 = _local_2_["log-again!"]
local RollbackManager = require("thyme.rollback")
local MacroRollbackManager = RollbackManager.new("macro", ".fnl")
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
  local _3fchunk
  do
    local _8_ = MacroRollbackManager["inject-mounted-backup-searcher!"](MacroRollbackManager, fennel["macro-searchers"])
    if (nil ~= _8_) then
      local searcher = _8_
      _3fchunk = searcher(module_name)
    else
      _3fchunk = nil
    end
  end
  local or_10_ = _3fchunk
  if not or_10_ then
    local _11_, _12_ = nil, nil
    do
      local _14_, _15_ = fennel["search-module"](module_name, fennel["macro-path"])
      if (nil ~= _14_) then
        local fnl_path = _14_
        _11_, _12_ = macro_module__3e_3fchunk(module_name, fnl_path)
      elseif (true and (nil ~= _15_)) then
        local _ = _14_
        local msg = _15_
        _11_, _12_ = nil, ("thyme-macro-searcher: " .. msg)
      else
        _11_, _12_ = nil
      end
    end
    if (nil ~= _11_) then
      local chunk = _11_
      or_10_ = chunk
    elseif (true and (nil ~= _12_)) then
      local _ = _11_
      local error_msg = _12_
      local backup_handler = MacroRollbackManager:backupHandlerOf(module_name)
      local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
      local Config = require("thyme.config")
      local _20_ = Config["?error-msg"]
      if (nil ~= _20_) then
        local msg = _20_
        or_10_ = nil
      else
        local _0 = _20_
        local max_rollbacks = Config["max-rollbacks"]
        local rollback_enabled_3f = (0 < max_rollbacks)
        if (rollback_enabled_3f and file_readable_3f(backup_path)) then
          local _25_, _26_ = macro_module__3e_3fchunk(module_name, backup_path)
          if (nil ~= _25_) then
            local chunk = _25_
            local msg = ("thyme-macro-rollback-loader: temporarily restore backup for the module %s (created at %s) due to the following error: %s\nHINT: You can reduce its annoying errors during repairing the module running `:ThymeRollbackMount` to keep the active backup in the next nvim session.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler), error_msg)
            vim.notify_once(msg, vim.log.levels.WARN)
            or_10_ = chunk
          elseif (true and (nil ~= _26_)) then
            local _1 = _25_
            local msg = _26_
            or_10_ = nil
          else
            or_10_ = nil
          end
        else
          or_10_ = nil
        end
      end
    else
      or_10_ = nil
    end
  end
  return or_10_
end
local function overwrite_metatable_21(original_table, cache_table)
  do
    local _35_ = getmetatable(original_table)
    if (nil ~= _35_) then
      local mt = _35_
      setmetatable(cache_table, mt)
    else
    end
  end
  local function _37_(self, module_name, val)
    if is_logged_3f(module_name) then
      rawset(self, module_name, nil)
      cache_table[module_name] = val
      return nil
    else
      return rawset(self, module_name, val)
    end
  end
  local function _39_(_, module_name)
    local _40_ = cache_table[module_name]
    if (nil ~= _40_) then
      local cached = _40_
      log_again_21(module_name)
      return cached
    else
      return nil
    end
  end
  return setmetatable(original_table, {__newindex = _37_, __index = _39_})
end
local function initialize_macro_searcher_on_rtp_21(fennel)
  table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)
  local function _42_(...)
    local _43_, _44_ = search_fnl_macro_on_rtp_21(...)
    if (nil ~= _43_) then
      local chunk = _43_
      return chunk
    elseif (true and (nil ~= _44_)) then
      local _ = _43_
      local msg = _44_
      return msg
    else
      return nil
    end
  end
  table.insert(package.loaders, _42_)
  return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"])
end
return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21}
