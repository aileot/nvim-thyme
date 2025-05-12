local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local Messenger = require("thyme.utils.messenger")
local SearcherMessenger = Messenger.new("macro-searcher")
local RollbackLoaderMessenger = Messenger.new("macro-rollback-loader")
local Observer = require("thyme.dependency.observer")
local RollbackManager = require("thyme.rollback")
local MacroRollbackManager = RollbackManager.new("macro", ".fnl")
local cache = {["macro-loaded"] = {}}
local function overwrite_metatable_21(original_table, cache_table)
  do
    local _2_ = getmetatable(original_table)
    if (nil ~= _2_) then
      local mt = _2_
      setmetatable(cache_table, mt)
    else
    end
  end
  local function _4_(self, module_name, val)
    if Observer["observed?"](Observer, module_name) then
      rawset(self, module_name, nil)
      cache_table[module_name] = val
      return nil
    else
      return rawset(self, module_name, val)
    end
  end
  local function _6_(_, module_name)
    local _7_ = cache_table[module_name]
    if (nil ~= _7_) then
      local cached = _7_
      Observer["log-dependent!"](Observer, module_name)
      return cached
    else
      return nil
    end
  end
  return setmetatable(original_table, {__newindex = _4_, __index = _6_})
end
local function macro_module__3e_3fchunk(module_name, fnl_path)
  local fennel = require("fennel")
  local Config = require("thyme.config")
  local compiler_options = Config["compiler-options"]
  local _3fenv = compiler_options.env
  compiler_options.env = "_COMPILER"
  local _9_, _10_ = Observer["observe!"](Observer, fennel.eval, fnl_path, nil, compiler_options, module_name)
  if ((_9_ == true) and (nil ~= _10_)) then
    local result = _10_
    local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
    local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
    if ((fnl_path ~= backup_path) and backup_handler["should-update-backup?"](backup_handler, read_file(fnl_path))) then
      backup_handler["write-backup!"](backup_handler, fnl_path)
      backup_handler["cleanup-old-backups!"](backup_handler)
    else
    end
    compiler_options.env = _3fenv
    local function _12_()
      return result
    end
    return _12_
  elseif (true and (nil ~= _10_)) then
    local _ = _9_
    local raw_msg = _10_
    local raw_msg_body = ("%s is found for the macro/%s, but failed to evaluate it in a compiler environment"):format(fnl_path, module_name)
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
    local _14_
    do
      local _15_ = MacroRollbackManager["inject-mounted-backup-searcher!"](MacroRollbackManager, fennel["macro-searchers"])
      if (nil ~= _15_) then
        local searcher = _15_
        _14_ = searcher(module_name)
      else
        _14_ = nil
      end
    end
    if (nil ~= _14_) then
      local msg_7cchunk = _14_
      local _17_ = type(msg_7cchunk)
      if (_17_ == "function") then
        _3fchunk = msg_7cchunk
      else
        _3fchunk = nil
      end
    else
      _3fchunk = nil
    end
  end
  local or_20_ = _3fchunk
  if not or_20_ then
    local _21_, _22_ = nil, nil
    do
      local _24_, _25_ = fennel["search-module"](module_name, fennel["macro-path"])
      if (nil ~= _24_) then
        local fnl_path = _24_
        _21_, _22_ = macro_module__3e_3fchunk(module_name, fnl_path)
      elseif (true and (nil ~= _25_)) then
        local _ = _24_
        local msg = _25_
        _21_, _22_ = nil, SearcherMessenger["wrap-msg"](SearcherMessenger, msg)
      else
        _21_, _22_ = nil
      end
    end
    if (nil ~= _21_) then
      local chunk = _21_
      or_20_ = chunk
    elseif (true and (nil ~= _22_)) then
      local _ = _21_
      local error_msg = _22_
      local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
      local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
      local Config = require("thyme.config")
      local _30_ = Config["?error-msg"]
      if (nil ~= _30_) then
        local msg = _30_
        or_20_ = nil
      else
        local _0 = _30_
        local max_rollbacks = Config["max-rollbacks"]
        local rollback_enabled_3f = (0 < max_rollbacks)
        if (rollback_enabled_3f and file_readable_3f(backup_path)) then
          local _35_, _36_ = macro_module__3e_3fchunk(module_name, backup_path)
          if (nil ~= _35_) then
            local chunk = _35_
            local msg = ("temporarily restore backup for the macro/%s (created at %s) due to the following error: %s\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_20_ = chunk
          elseif (true and (nil ~= _36_)) then
            local _1 = _35_
            local msg = _36_
            or_20_ = nil
          else
            or_20_ = nil
          end
        else
          or_20_ = nil
        end
      end
    else
      or_20_ = nil
    end
  end
  return or_20_
end
local function initialize_macro_searcher_on_rtp_21(fennel)
  table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)
  local function _45_(...)
    local _46_, _47_ = search_fnl_macro_on_rtp_21(...)
    if (nil ~= _46_) then
      local chunk = _46_
      return chunk
    elseif (true and (nil ~= _47_)) then
      local _ = _46_
      local msg = _47_
      return msg
    else
      return nil
    end
  end
  table.insert(package.loaders, _45_)
  return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"])
end
return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21}
