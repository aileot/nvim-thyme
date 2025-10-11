local _local_1_ = require("thyme.util.general")
local validate_type = _local_1_["validate-type"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local read_file = _local_2_["read-file"]
local Messenger = require("thyme.util.class.messenger")
local MacroLoaderMessenger = Messenger.new("loader/macro")
local RollbackLoaderMessenger = Messenger.new("loader/macro/rollback")
local Observer = require("thyme.dependency.observer")
local RollbackManager = require("thyme.rollback.manager")
local MacroRollbackManager = RollbackManager.new("macro", ".fnl")
local cache = {["macro-loaded"] = {}, ["__macro-loaded"] = {}, ["mounted-rollback-searcher"] = nil}
local function overwrite_metatable_21(original_table, cache_table)
  do
    local case_3_ = getmetatable(original_table)
    if (nil ~= case_3_) then
      local mt = case_3_
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
    local case_8_ = cache_table[module_name]
    if (nil ~= case_8_) then
      local cached = case_8_
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
  local case_10_, case_11_ = Observer["observe!"](Observer, fennel.eval, fnl_path, nil, compiler_options, module_name)
  if ((case_10_ == true) and (nil ~= case_11_)) then
    local result = case_11_
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
  elseif (true and (nil ~= case_11_)) then
    local _ = case_10_
    local raw_msg = case_11_
    local raw_msg_body = ("%s is found for the macro/%s, but failed to evaluate it in a compiler environment"):format(fnl_path, module_name)
    local msg = MacroLoaderMessenger["mk-failure-reason"](MacroLoaderMessenger, ("%s\n\t%s"):format(raw_msg_body, raw_msg))
    compiler_options.env = _3fenv
    return nil, msg
  else
    return nil
  end
end
local function search_fnl_macro_on_rtp_21(module_name)
  local fennel = require("fennel")
  local case_15_
  if cache["mounted-rollback-searcher"] then
    case_15_ = cache["mounted-rollback-searcher"](module_name)
  else
    local macro_file_loader
    local function _16_(fnl_path, module_name0)
      return macro_module__3e_3fchunk(module_name0, fnl_path)
    end
    macro_file_loader = _16_
    local case_17_ = MacroRollbackManager["inject-mounted-backup-searcher!"](MacroRollbackManager, fennel["macro-searchers"], macro_file_loader)
    if (nil ~= case_17_) then
      local searcher = case_17_
      validate_type("function", searcher)
      cache["mounted-rollback-searcher"] = searcher
      case_15_ = searcher(module_name)
    else
      case_15_ = nil
    end
  end
  if (nil ~= case_15_) then
    local chunk = case_15_
    return chunk
  else
    local _ = case_15_
    local case_20_, case_21_
    do
      local case_22_, case_23_ = fennel["search-module"](module_name, fennel["macro-path"])
      if (nil ~= case_22_) then
        local fnl_path = case_22_
        case_20_, case_21_ = macro_module__3e_3fchunk(module_name, fnl_path)
      elseif (true and (nil ~= case_23_)) then
        local _0 = case_22_
        local msg = case_23_
        case_20_, case_21_ = nil, msg
      else
        case_20_, case_21_ = nil
      end
    end
    if (nil ~= case_20_) then
      local chunk = case_20_
      return chunk
    elseif (true and (nil ~= case_21_)) then
      local _0 = case_20_
      local error_msg = case_21_
      local backup_handler = MacroRollbackManager["backup-handler-of"](MacroRollbackManager, module_name)
      local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
      local Config = require("thyme.config")
      local case_25_ = Config["?error-msg"]
      if (nil ~= case_25_) then
        local msg = case_25_
        return nil, MacroLoaderMessenger["mk-failure-reason"](MacroLoaderMessenger, msg)
      else
        local _1 = case_25_
        local max_rollbacks = Config["max-rollbacks"]
        local rollback_enabled_3f = (0 < max_rollbacks)
        local case_26_
        if (rollback_enabled_3f and file_readable_3f(backup_path)) then
          local case_27_ = macro_module__3e_3fchunk(module_name, backup_path)
          if (nil ~= case_27_) then
            local chunk = case_27_
            local msg = ("temporarily restore backup for the macro/%s (created at %s) due to the following error:\n%s\n\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            case_26_ = chunk
          else
            case_26_ = nil
          end
        else
          case_26_ = nil
        end
        if (nil ~= case_26_) then
          local chunk = case_26_
          return chunk
        else
          local _2 = case_26_
          return nil, MacroLoaderMessenger["mk-failure-reason"](MacroLoaderMessenger, error_msg)
        end
      end
    else
      return nil
    end
  end
end
local function initialize_macro_searcher_on_rtp_21(fennel)
  table.insert(fennel["macro-searchers"], 1, search_fnl_macro_on_rtp_21)
  local function _34_(...)
    local case_35_, case_36_ = search_fnl_macro_on_rtp_21(...)
    if (nil ~= case_35_) then
      local chunk = case_35_
      return chunk
    elseif (true and (nil ~= case_36_)) then
      local _ = case_35_
      local msg = case_36_
      return msg
    else
      return nil
    end
  end
  table.insert(package.loaders, _34_)
  return overwrite_metatable_21(fennel["macro-loaded"], cache["macro-loaded"])
end
local function hide_macro_cache_21(module_name)
  if (nil == module_name) then
    _G.error("Missing argument module-name on fnl/thyme/loader/macro-module.fnl:154", 2)
  else
  end
  cache["__macro-loaded"][module_name] = cache["macro-loaded"][module_name]
  cache["macro-loaded"][module_name] = nil
  return nil
end
local function restore_macro_cache_21(module_name)
  if (nil == module_name) then
    _G.error("Missing argument module-name on fnl/thyme/loader/macro-module.fnl:161", 2)
  else
  end
  cache["macro-loaded"][module_name] = cache["__macro-loaded"][module_name]
  cache["__macro-loaded"][module_name] = nil
  return nil
end
return {["initialize-macro-searcher-on-rtp!"] = initialize_macro_searcher_on_rtp_21, ["search-fnl-macro-on-rtp!"] = search_fnl_macro_on_rtp_21, ["hide-macro-cache!"] = hide_macro_cache_21, ["restore-macro-cache!"] = restore_macro_cache_21}
