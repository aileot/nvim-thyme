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
local function macro_module__3e_3fchunk(module_name, fnl_path)
  local fennel = require("fennel")
  local Config = require("thyme.config")
  local compiler_options = Config["compiler-options"]
  local _3fenv = compiler_options.env
  compiler_options.env = "_COMPILER"
  local _2_, _3_ = Observer["observe!"](Observer, fennel.eval, fnl_path, nil, compiler_options, module_name)
  if ((_2_ == true) and (nil ~= _3_)) then
    local result = _3_
    local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
    local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
    if ((fnl_path ~= backup_path) and backup_handler["should-update-backup?"](backup_handler, read_file(fnl_path))) then
      backup_handler["write-backup!"](backup_handler, fnl_path)
      backup_handler["cleanup-old-backups!"](backup_handler)
    else
    end
    compiler_options.env = _3fenv
    local function _5_()
      return result
    end
    return _5_
  elseif (true and (nil ~= _3_)) then
    local _ = _2_
    local raw_msg = _3_
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
    local _7_
    do
      local _8_ = MacroRollbackManager["inject-mounted-backup-searcher!"](MacroRollbackManager, fennel["macro-searchers"])
      if (nil ~= _8_) then
        local searcher = _8_
        _7_ = searcher(module_name)
      else
        _7_ = nil
      end
    end
    if (nil ~= _7_) then
      local msg_7cchunk = _7_
      local _10_ = type(msg_7cchunk)
      if (_10_ == "function") then
        _3fchunk = msg_7cchunk
      else
        _3fchunk = nil
      end
    else
      _3fchunk = nil
    end
  end
  local or_13_ = _3fchunk
  if not or_13_ then
    local _14_, _15_ = nil, nil
    do
      local _17_, _18_ = fennel["search-module"](module_name, fennel["macro-path"])
      if (nil ~= _17_) then
        local fnl_path = _17_
        _14_, _15_ = macro_module__3e_3fchunk(module_name, fnl_path)
      elseif (true and (nil ~= _18_)) then
        local _ = _17_
        local msg = _18_
        _14_, _15_ = nil, SearcherMessenger["wrap-msg"](SearcherMessenger, msg)
      else
        _14_, _15_ = nil
      end
    end
    if (nil ~= _14_) then
      local chunk = _14_
      or_13_ = chunk
    elseif (true and (nil ~= _15_)) then
      local _ = _14_
      local error_msg = _15_
      local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
      local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
      local Config = require("thyme.config")
      local _23_ = Config["?error-msg"]
      if (nil ~= _23_) then
        local msg = _23_
        or_13_ = nil
      else
        local _0 = _23_
        local max_rollbacks = Config["max-rollbacks"]
        local rollback_enabled_3f = (0 < max_rollbacks)
        if (rollback_enabled_3f and file_readable_3f(backup_path)) then
          local _28_, _29_ = macro_module__3e_3fchunk(module_name, backup_path)
          if (nil ~= _28_) then
            local chunk = _28_
            local msg = ("temporarily restore backup for the module %s (created at %s) due to the following error: %s\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_13_ = chunk
          elseif (true and (nil ~= _29_)) then
            local _1 = _28_
            local msg = _29_
            or_13_ = nil
          else
            or_13_ = nil
          end
        else
          or_13_ = nil
        end
      end
    else
      or_13_ = nil
    end
  end
  return or_13_
end
local function overwrite_metatable_21(original_table, cache_table)
  do
    local _38_ = getmetatable(original_table)
    if (nil ~= _38_) then
      local mt = _38_
      setmetatable(cache_table, mt)
    else
    end
  end
  local function _40_(self, module_name, val)
    if Observer["is-logged?"](Observer, module_name) then
      rawset(self, module_name, nil)
      cache_table[module_name] = val
      return nil
    else
      return rawset(self, module_name, val)
    end
  end
  local function _42_(_, module_name)
    local _43_ = cache_table[module_name]
    if (nil ~= _43_) then
      local cached = _43_
      Observer["log-dependent!"](Observer, module_name)
      return cached
    else
      return nil
    end
  end
  return setmetatable(original_table, {__newindex = _40_, __index = _42_})
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
