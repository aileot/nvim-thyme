local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local Messenger = require("thyme.utils.messenger")
local SearcherMessenger = Messenger.new("macro-searcher")
local RollbackLoaderMessenger = Messenger.new("macro-rollback-loader")
local _local_2_ = require("thyme.dependency.observer")
local observe_21 = _local_2_["observe!"]
local is_logged_3f = _local_2_["is-logged?"]
local log_dependent_21 = _local_2_["log-dependent!"]
local RollbackManager = require("thyme.rollback")
local MacroRollbackManager = RollbackManager.new("macro", ".fnl")
local cache = {["macro-loaded"] = {}}
local function macro_module__3e_3fchunk(module_name, fnl_path)
  local fennel = require("fennel")
  local Config = require("thyme.config")
  local compiler_options = Config["compiler-options"]
  local _3fenv = compiler_options.env
  compiler_options.env = "_COMPILER"
  local _3_, _4_ = observe_21(fennel.eval, fnl_path, nil, compiler_options, module_name)
  if ((_3_ == true) and (nil ~= _4_)) then
    local result = _4_
    local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
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
    local raw_msg = _4_
    local raw_msg_body = ("%s is found for the macro module %s, but failed to evaluate it in a compiler environment"):format(fnl_path, module_name)
    local msg_body = SearcherMessenger["wrap-msg"](SearcherMessenger, raw_msg_body)
    local msg = ("\n%s\n\9%s"):format(msg_body, raw_msg)
    compiler_options.env = _3fenv
    return nil, msg
  else
    return nil
  end
end
local function search_fnl_macro_on_rtp_21(module_name)
  local fennel = require("fennel")
  local _3fchunk
  do
    local _8_
    do
      local _9_ = MacroRollbackManager["inject-mounted-backup-searcher!"](MacroRollbackManager, fennel["macro-searchers"])
      if (nil ~= _9_) then
        local searcher = _9_
        _8_ = searcher(module_name)
      else
        _8_ = nil
      end
    end
    if (nil ~= _8_) then
      local msg_7cchunk = _8_
      local _11_ = type(msg_7cchunk)
      if (_11_ == "function") then
        _3fchunk = msg_7cchunk
      else
        _3fchunk = nil
      end
    else
      _3fchunk = nil
    end
  end
  local or_14_ = _3fchunk
  if not or_14_ then
    local _15_, _16_ = nil, nil
    do
      local _18_, _19_ = fennel["search-module"](module_name, fennel["macro-path"])
      if (nil ~= _18_) then
        local fnl_path = _18_
        _15_, _16_ = macro_module__3e_3fchunk(module_name, fnl_path)
      elseif (true and (nil ~= _19_)) then
        local _ = _18_
        local msg = _19_
        _15_, _16_ = nil, SearcherMessenger["wrap-msg"](SearcherMessenger, msg)
      else
        _15_, _16_ = nil
      end
    end
    if (nil ~= _15_) then
      local chunk = _15_
      or_14_ = chunk
    elseif (true and (nil ~= _16_)) then
      local _ = _15_
      local error_msg = _16_
      local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
      local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
      local Config = require("thyme.config")
      local _24_ = Config["?error-msg"]
      if (nil ~= _24_) then
        local msg = _24_
        or_14_ = nil
      else
        local _0 = _24_
        local max_rollbacks = Config["max-rollbacks"]
        local rollback_enabled_3f = (0 < max_rollbacks)
        if (rollback_enabled_3f and file_readable_3f(backup_path)) then
          local _29_, _30_ = macro_module__3e_3fchunk(module_name, backup_path)
          if (nil ~= _29_) then
            local chunk = _29_
            local msg = ("temporarily restore backup for the module %s (created at %s) due to the following error: %s\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_14_ = chunk
          elseif (true and (nil ~= _30_)) then
            local _1 = _29_
            local msg = _30_
            or_14_ = nil
          else
            or_14_ = nil
          end
        else
          or_14_ = nil
        end
      end
    else
      or_14_ = nil
    end
  end
  return or_14_
end
local function overwrite_metatable_21(original_table, cache_table)
  do
    local _39_ = getmetatable(original_table)
    if (nil ~= _39_) then
      local mt = _39_
      setmetatable(cache_table, mt)
    else
    end
  end
  local function _41_(self, module_name, val)
    if is_logged_3f(module_name) then
      rawset(self, module_name, nil)
      cache_table[module_name] = val
      return nil
    else
      return rawset(self, module_name, val)
    end
  end
  local function _43_(_, module_name)
    local _44_ = cache_table[module_name]
    if (nil ~= _44_) then
      local cached = _44_
      log_dependent_21(module_name)
      return cached
    else
      return nil
    end
  end
  return setmetatable(original_table, {__newindex = _41_, __index = _43_})
end
local function initialize_macro_searcher_on_rtp_21(fennel)
  table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)
  local function _46_(...)
    local _47_, _48_ = search_fnl_macro_on_rtp_21(...)
    if (nil ~= _47_) then
      local chunk = _47_
      return chunk
    elseif (true and (nil ~= _48_)) then
      local _ = _47_
      local msg = _48_
      return msg
    else
      return nil
    end
  end
  table.insert(package.loaders, _46_)
  return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"])
end
return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21}
