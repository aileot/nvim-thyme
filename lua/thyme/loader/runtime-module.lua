local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local write_lua_file_21 = _local_2_["write-lua-file!"]
local _local_3_ = require("thyme.util.iterator")
local gsplit = _local_3_["gsplit"]
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
    local tbl_21_ = {}
    local i_22_ = 0
    for _, suffix in ipairs({"?.fnl", "?/init.fnl"}) do
      local val_23_ = (std_config_home .. fnl_dir .. suffix)
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _8_ = tbl_21_
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
    local tbl_21_ = {}
    local i_22_ = 0
    for fnl_template in gsplit(Config["macro-path"], ";") do
      local val_23_
      if ("/" == fnl_template:sub(1, 1)) then
        val_23_ = fnl_template
      else
        local offset, rest = fnl_template:match("^%./([^?]*)(.-)$")
        local base_paths = base_path_cache[offset]
        local _12_
        do
          local tbl_21_0 = {}
          local i_22_0 = 0
          for _, dir in pairs(base_paths) do
            local val_23_0 = (dir .. rest)
            if (nil ~= val_23_0) then
              i_22_0 = (i_22_0 + 1)
              tbl_21_0[i_22_0] = val_23_0
            else
            end
          end
          _12_ = tbl_21_0
        end
        val_23_ = table.concat(_12_, ";")
      end
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _11_ = tbl_21_
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
        local _20_
        do
          local _22_ = RuntimeModuleRollbackManager["inject-mounted-backup-searcher!"](RuntimeModuleRollbackManager, package.loaders, file_loader)
          if (nil ~= _22_) then
            local searcher = _22_
            _20_ = searcher(module_name)
          else
            _20_ = nil
          end
        end
        if (nil ~= _20_) then
          local msg_7cchunk = _20_
          local _25_ = type(msg_7cchunk)
          if (_25_ == "function") then
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
        local _31_, _32_ = nil, nil
        do
          local _34_, _35_ = module_name__3efnl_file_on_rtp_21(module_name)
          if (nil ~= _34_) then
            local fnl_path = _34_
            local fennel = require("fennel")
            local _let_36_ = require("thyme.compiler.cache")
            local determine_lua_path = _let_36_["determine-lua-path"]
            local lua_path = determine_lua_path(module_name)
            local compiler_options = Config["compiler-options"]
            local _37_, _38_ = Observer["observe!"](Observer, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
            if ((_37_ == true) and (nil ~= _38_)) then
              local lua_code = _38_
              if can_restore_file_3f(lua_path, lua_code) then
                restore_file_21(lua_path)
              else
                write_lua_file_with_backup_21(lua_path, lua_code, module_name)
                backup_handler["cleanup-old-backups!"](backup_handler)
              end
              _31_, _32_ = load(lua_code, lua_path)
            elseif (true and (nil ~= _38_)) then
              local _ = _37_
              local raw_msg = _38_
              local raw_msg_body = ("%s is found for the runtime/%s, but failed to compile it"):format(fnl_path, module_name)
              local msg = LoaderMessenger["mk-failure-reason"](LoaderMessenger, ("%s\n	%s"):format(raw_msg_body, raw_msg))
              _31_, _32_ = nil, msg
            else
              _31_, _32_ = nil
            end
          elseif (true and (nil ~= _35_)) then
            local _ = _34_
            local raw_msg = _35_
            _31_, _32_ = nil, raw_msg
          else
            _31_, _32_ = nil
          end
        end
        if (nil ~= _31_) then
          local chunk = _31_
          or_30_ = chunk
        elseif (true and (nil ~= _32_)) then
          local _ = _31_
          local error_msg = _32_
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
