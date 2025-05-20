local _local_1_ = require("thyme.utils.general")
local validate_type = _local_1_["validate-type"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local read_file = _local_2_["read-file"]
local Messenger = require("thyme.utils.messenger")
local SearcherMessenger = Messenger.new("searcher/macro")
local RollbackLoaderMessenger = Messenger.new("searcher/macro/rollback")
local Observer = require("thyme.dependency.observer")
local RollbackManager = require("thyme.rollback.manager")
local MacroRollbackManager = RollbackManager.new("macro", ".fnl")
local cache = {["macro-loaded"] = {}, ["mounted-rollback-searcher"] = nil}
local function overwrite_metatable_21(original_table, cache_table)
  do
    local _3_ = getmetatable(original_table)
    if (nil ~= _3_) then
      local mt = _3_
      setmetatable(cache_table, mt)
    else
    end
  end
  local function _5_(self, module_name, val)
    if Observer["observed?"](Observer, module_name) then
      rawset(self, module_name, nil)
      cache_table[module_name] = val
      return nil
    else
      return rawset(self, module_name, val)
    end
  end
  local function _7_(_, module_name)
    local _8_ = cache_table[module_name]
    if (nil ~= _8_) then
      local cached = _8_
      Observer["log-dependent!"](Observer, module_name)
      return cached
    else
      return nil
    end
  end
  return setmetatable(original_table, {__newindex = _5_, __index = _7_})
end
local function macro_module__3e_3fchunk(module_name, fnl_path)
  local fennel = require("fennel")
  local Config = require("thyme.config")
  local compiler_options = Config["compiler-options"]
  local _3fenv = compiler_options.env
  compiler_options.env = "_COMPILER"
  local _10_, _11_ = Observer["observe!"](Observer, fennel.eval, fnl_path, nil, compiler_options, module_name)
  if ((_10_ == true) and (nil ~= _11_)) then
    local result = _11_
    local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
    local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
    if ((fnl_path ~= backup_path) and backup_handler["should-update-backup?"](backup_handler, read_file(fnl_path))) then
      backup_handler["write-backup!"](backup_handler, fnl_path)
      backup_handler["cleanup-old-backups!"](backup_handler)
    else
    end
    compiler_options.env = _3fenv
    local function _13_()
      return result
    end
    return _13_
  elseif (true and (nil ~= _11_)) then
    local _ = _10_
    local raw_msg = _11_
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
  if cache["mounted-rollback-searcher"] then
    _3fchunk = cache["mounted-rollback-searcher"](module_name)
  else
    local macro_file_loader
    local function _15_(fnl_path, module_name0)
      return macro_module__3e_3fchunk(module_name0, fnl_path)
    end
    macro_file_loader = _15_
    local _16_ = MacroRollbackManager["inject-mounted-backup-searcher!"](MacroRollbackManager, fennel["macro-searchers"], macro_file_loader)
    if (nil ~= _16_) then
      local searcher = _16_
      validate_type("function", searcher)
      cache["mounted-rollback-searcher"] = searcher
      _3fchunk = searcher(module_name)
    else
      _3fchunk = nil
    end
  end
  local or_19_ = _3fchunk
  if not or_19_ then
    local _20_, _21_ = nil, nil
    do
      local _23_, _24_ = fennel["search-module"](module_name, fennel["macro-path"])
      if (nil ~= _23_) then
        local fnl_path = _23_
        _20_, _21_ = macro_module__3e_3fchunk(module_name, fnl_path)
      elseif (true and (nil ~= _24_)) then
        local _ = _23_
        local msg = _24_
        _20_, _21_ = nil, SearcherMessenger["wrap-msg"](SearcherMessenger, msg)
      else
        _20_, _21_ = nil
      end
    end
    if (nil ~= _20_) then
      local chunk = _20_
      or_19_ = chunk
    elseif (true and (nil ~= _21_)) then
      local _ = _20_
      local error_msg = _21_
      local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
      local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
      local Config = require("thyme.config")
      local _29_ = Config["?error-msg"]
      if (nil ~= _29_) then
        local msg = _29_
        or_19_ = nil
      else
        local _0 = _29_
        local max_rollbacks = Config["max-rollbacks"]
        local rollback_enabled_3f = (0 < max_rollbacks)
        if (rollback_enabled_3f and file_readable_3f(backup_path)) then
          local _34_, _35_ = macro_module__3e_3fchunk(module_name, backup_path)
          if (nil ~= _34_) then
            local chunk = _34_
            local msg = ("temporarily restore backup for the macro/%s (created at %s) due to the following error: %s\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_19_ = chunk
          elseif (true and (nil ~= _35_)) then
            local _1 = _34_
            local msg = _35_
            or_19_ = nil
          else
            or_19_ = nil
          end
        else
          or_19_ = nil
        end
      end
    else
      or_19_ = nil
    end
  end
  return or_19_
end
local function initialize_macro_searcher_on_rtp_21(fennel)
  table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)
  local function _44_(...)
    local _45_, _46_ = search_fnl_macro_on_rtp_21(...)
    if (nil ~= _45_) then
      local chunk = _45_
      return chunk
    elseif (true and (nil ~= _46_)) then
      local _ = _45_
      local msg = _46_
      return msg
    else
      return nil
    end
  end
  table.insert(package.loaders, _44_)
  return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"])
end
return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21}
