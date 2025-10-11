local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local write_lua_file_21 = _local_2_["write-lua-file!"]
local _local_3_ = require("thyme.util.iterator")
local gsplit = _local_3_.gsplit
local _local_4_ = require("thyme.util.pool")
local can_restore_file_3f = _local_4_["can-restore-file?"]
local restore_file_21 = _local_4_["restore-file!"]
local Messenger = require("thyme.util.class.messenger")
local LoaderMessenger = Messenger.new("loader/runtime")
local RollbackLoaderMessenger = Messenger.new("loader/runtime/rollback")
local _local_5_ = require("thyme.wrapper.nvim")
local get_runtime_files = _local_5_["get-runtime-files"]
local Observer = require("thyme.dependency.observer")
local _local_6_ = require("thyme.loader.fennel-module")
local locate_fennel_path_21 = _local_6_["locate-fennel-path!"]
local load_fennel = _local_6_["load-fennel"]
local _local_7_ = require("thyme.loader.macro-module")
local initialize_macro_searcher_on_rtp_21 = _local_7_["initialize-macro-searcher-on-rtp!"]
local RollbackManager = require("thyme.rollback.manager")
local RuntimeModuleRollbackManager = RollbackManager.new("runtime", ".lua")
local cache = {rtp = nil}
local function initialize_module_searcher_on_rtp_21(fennel)
  local std_config_home = vim.fn.stdpath("config")
  local Config = require("thyme.config")
  local fnl_dir = string.gsub(("/" .. Config["fnl-dir"] .. "/"), "//+", "/")
  local fennel_path
  local _8_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, suffix in ipairs({"?.fnl", "?/init.fnl"}) do
      local val_28_ = (std_config_home .. fnl_dir .. suffix)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _8_ = tbl_26_
  end
  fennel_path = table.concat(_8_, ";")
  fennel.path = fennel_path
  return nil
end
local function update_fennel_paths_21(fennel)
  local Config = require("thyme.config")
  local base_path_cache
  local function _10_(self, key)
    rawset(self, key, get_runtime_files({key}, true))
    return self[key]
  end
  base_path_cache = setmetatable({}, {__index = _10_})
  local macro_path
  local _11_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for fnl_template in gsplit(Config["macro-path"], ";") do
      local val_28_
      if ("/" == fnl_template:sub(1, 1)) then
        val_28_ = fnl_template
      else
        local offset, rest = fnl_template:match("^%./([^?]*)(.-)$")
        local base_paths = base_path_cache[offset]
        local _12_
        do
          local tbl_26_0 = {}
          local i_27_0 = 0
          for _, dir in pairs(base_paths) do
            local val_28_0 = (dir .. rest)
            if (nil ~= val_28_0) then
              i_27_0 = (i_27_0 + 1)
              tbl_26_0[i_27_0] = val_28_0
            else
            end
          end
          _12_ = tbl_26_0
        end
        val_28_ = table.concat(_12_, ";")
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _11_ = tbl_26_
  end
  macro_path = table.concat(_11_, ";"):gsub("/%./", "/")
  fennel["macro-path"] = macro_path
  return nil
end
local function write_lua_file_with_backup_21(lua_path, lua_code, module_name)
  write_lua_file_21(lua_path, lua_code)
  local backup_handler = RuntimeModuleRollbackManager["backup-handler-of"](RuntimeModuleRollbackManager, module_name)
  if backup_handler["should-update-backup?"](backup_handler, lua_code) then
    return backup_handler["write-backup!"](backup_handler, lua_path)
  else
    return nil
  end
end
local function module_name__3efnl_file_on_rtp_21(module_name)
  local fennel = require("fennel")
  if ((nil == cache.rtp) or debug_3f) then
    initialize_macro_searcher_on_rtp_21(fennel)
    initialize_module_searcher_on_rtp_21(fennel)
  else
  end
  if not (cache.rtp == vim.o.rtp) then
    cache.rtp = vim.o.rtp
    update_fennel_paths_21(fennel)
  else
  end
  return fennel["search-module"](module_name, fennel.path)
end
local function search_fnl_module_on_rtp_21(module_name, ...)
  if string.find(module_name, "^vim%.") then
    local path = vim.fs.joinpath(vim.env.VIMRUNTIME, "lua")
    return loadfile(path)
  elseif ("fennel" == module_name) then
    local fennel_lua_path = locate_fennel_path_21()
    return load_fennel(fennel_lua_path)
  else
    local Config = require("thyme.config")
    if Config["?error-msg"] then
      return LoaderMessenger["mk-failure-reason"](LoaderMessenger, Config["?error-msg"])
    else
      local backup_handler = RuntimeModuleRollbackManager["backup-handler-of"](RuntimeModuleRollbackManager, module_name)
      local file_loader
      local function _19_(path, ...)
        return loadfile(path)
      end
      file_loader = _19_
      local _21_
      do
        local case_20_
        do
          local case_22_ = RuntimeModuleRollbackManager["inject-mounted-backup-searcher!"](RuntimeModuleRollbackManager, package.loaders, file_loader)
          if (nil ~= case_22_) then
            local searcher = case_22_
            case_20_ = searcher(module_name)
          else
            case_20_ = nil
          end
        end
        if (nil ~= case_20_) then
          local msg_7cchunk = case_20_
          local case_25_ = type(msg_7cchunk)
          if (case_25_ == "function") then
            _21_ = msg_7cchunk
          else
            _21_ = nil
          end
        else
          _21_ = nil
        end
      end
      local or_30_ = _21_
      if not or_30_ then
        local case_31_, case_32_
        do
          local case_34_, case_35_ = module_name__3efnl_file_on_rtp_21(module_name)
          if (nil ~= case_34_) then
            local fnl_path = case_34_
            local fennel = require("fennel")
            local _let_36_ = require("thyme.compiler.cache")
            local determine_lua_path = _let_36_["determine-lua-path"]
            local lua_path = determine_lua_path(module_name)
            local compiler_options = Config["compiler-options"]
            local case_37_, case_38_ = Observer["observe!"](Observer, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
            if ((case_37_ == true) and (nil ~= case_38_)) then
              local lua_code = case_38_
              if can_restore_file_3f(lua_path, lua_code) then
                restore_file_21(lua_path)
              else
                write_lua_file_with_backup_21(lua_path, lua_code, module_name)
                backup_handler["cleanup-old-backups!"](backup_handler)
              end
              case_31_, case_32_ = load(lua_code, lua_path)
            elseif (true and (nil ~= case_38_)) then
              local _ = case_37_
              local raw_msg = case_38_
              local raw_msg_body = ("%s is found for the runtime/%s, but failed to compile it"):format(fnl_path, module_name)
              local msg = LoaderMessenger["mk-failure-reason"](LoaderMessenger, ("%s\n\t%s"):format(raw_msg_body, raw_msg))
              case_31_, case_32_ = nil, msg
            else
              case_31_, case_32_ = nil
            end
          elseif (true and (nil ~= case_35_)) then
            local _ = case_34_
            local raw_msg = case_35_
            case_31_, case_32_ = nil, raw_msg
          else
            case_31_, case_32_ = nil
          end
        end
        if (nil ~= case_31_) then
          local chunk = case_31_
          or_30_ = chunk
        elseif (true and (nil ~= case_32_)) then
          local _ = case_31_
          local error_msg = case_32_
          local backup_path = backup_handler["determine-active-backup-path"](backup_handler, module_name)
          local max_rollbacks = Config["max-rollbacks"]
          local rollback_enabled_3f = (0 < max_rollbacks)
          if (rollback_enabled_3f and file_readable_3f(backup_path)) then
            local msg = ("temporarily restore backup for the module/%s (created at %s) due to the following error:\n%s\n\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_30_ = loadfile(backup_path)
          else
            or_30_ = LoaderMessenger["mk-failure-reason"](LoaderMessenger, error_msg)
          end
        else
          or_30_ = nil
        end
      end
      return or_30_
    end
  end
end
return {["search-fnl-module-on-rtp!"] = search_fnl_module_on_rtp_21, ["write-lua-file-with-backup!"] = write_lua_file_with_backup_21, RuntimeModuleRollbackManager = RuntimeModuleRollbackManager}
