local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local read_file = _local_2_["read-file"]
local write_lua_file_21 = _local_2_["write-lua-file!"]
local fs = _local_2_
local _local_3_ = require("thyme.utils.iterator")
local gsplit = _local_3_["gsplit"]
local _local_4_ = require("thyme.utils.pool")
local can_restore_file_3f = _local_4_["can-restore-file?"]
local restore_file_21 = _local_4_["restore-file!"]
local _local_5_ = require("thyme.wrapper.nvim")
local get_runtime_files = _local_5_["get-runtime-files"]
local Config = require("thyme.config")
local _local_6_ = require("thyme.module-map.callstack")
local pcall_with_logger_21 = _local_6_["pcall-with-logger!"]
local _local_7_ = require("thyme.searcher.macro")
local initialize_macro_searcher_on_rtp_21 = _local_7_["initialize-macro-searcher-on-rtp!"]
local RollbackManager = require("thyme.rollback")
local ModuleRollbackManager = RollbackManager.new("module", ".lua")
local cache = {rtp = nil}
local function compile_fennel_into_rtp_21()
  local rtp = vim.api.nvim_get_option_value("rtp", {})
  local fnl_src_path = (rtp:match(Path.join("([^,]+", "fennel),")) or rtp:match(Path.join("([^,]+", "fennel)$")) or error("please make sure to add the path to fennel repo in `&runtimepath`"))
  local fennel_lua_file = "fennel.lua"
  local cached_fennel_path = Path.join(lua_cache_prefix, fennel_lua_file)
  local _let_8_ = vim.fs.find("Makefile", {upward = true, path = fnl_src_path})
  local fennel_src_Makefile = _let_8_[1]
  local _ = assert(fennel_src_Makefile, "Could not find Makefile for fennel.lua.")
  local fennel_src_root = vim.fs.dirname(fennel_src_Makefile)
  local fennel_lua_path = Path.join(fennel_src_root, fennel_lua_file)
  local output = vim.fn.system({"make", "-C", fennel_src_root, fennel_lua_file})
  if not (0 == vim.v.shell_error) then
    error(("failed to compile fennel.lua with exit code: " .. vim.v.shell_error .. "\ndump:\n" .. output))
  else
  end
  vim.fn.mkdir(vim.fs.dirname(cached_fennel_path), "p")
  if can_restore_file_3f(cached_fennel_path, read_file(fennel_lua_path)) then
    restore_file_21(cached_fennel_path)
  else
    fs.copyfile(fennel_lua_path, cached_fennel_path)
  end
  assert_is_file_readable(fennel_lua_path)
  assert_is_file_readable(cached_fennel_path)
  return assert(loadfile(cached_fennel_path))
end
local function initialize_module_searcher_on_rtp_21(fennel)
  local std_config_home = vim.fn.stdpath("config")
  local fnl_dir = string.gsub(("/" .. Config["fnl-dir"] .. "/"), "//+", "/")
  local fennel_path
  local _11_
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, suffix in ipairs({"?.fnl", "?/init.fnl"}) do
      local val_23_auto = (std_config_home .. fnl_dir .. suffix)
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    _11_ = tbl_21_auto
  end
  fennel_path = table.concat(_11_, ";")
  fennel.path = fennel_path
  return nil
end
local function update_fennel_paths_21(fennel)
  local base_path_cache
  local function _13_(self, key)
    rawset(self, key, get_runtime_files({key}, true))
    return self[key]
  end
  base_path_cache = setmetatable({}, {__index = _13_})
  local macro_path
  local _14_
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for fnl_template in gsplit(Config["macro-path"], ";") do
      local val_23_auto
      if ("/" == fnl_template:sub(1, 1)) then
        val_23_auto = fnl_template
      else
        local offset, rest = fnl_template:match("^%./([^?]*)(.-)$")
        local base_paths = base_path_cache[offset]
        local _15_
        do
          local tbl_21_auto0 = {}
          local i_22_auto0 = 0
          for _, dir in pairs(base_paths) do
            local val_23_auto0 = (dir .. rest)
            if (nil ~= val_23_auto0) then
              i_22_auto0 = (i_22_auto0 + 1)
              tbl_21_auto0[i_22_auto0] = val_23_auto0
            else
            end
          end
          _15_ = tbl_21_auto0
        end
        val_23_auto = table.concat(_15_, ";")
      end
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    _14_ = tbl_21_auto
  end
  macro_path = table.concat(_14_, ";"):gsub("/%./", "/")
  fennel["macro-path"] = macro_path
  return nil
end
local function write_lua_file_with_backup_21(lua_path, lua_code, module_name)
  write_lua_file_21(lua_path, lua_code)
  local backup_handler = ModuleRollbackManager:backupHandlerOf(module_name)
  if backup_handler["should-update-backup?"](backup_handler, lua_code) then
    return backup_handler["write-backup!"](backup_handler, lua_path)
  else
    return nil
  end
end
local function search_fnl_module_on_rtp_21(module_name, ...)
  if ("fennel" == module_name) then
    return compile_fennel_into_rtp_21()
  else
    local fennel = require("fennel")
    local or_20_ = Config["?error-msg"]
    if not or_20_ then
      local backup_handler = ModuleRollbackManager:backupHandlerOf(module_name)
      ModuleRollbackManager["inject-mounted-backup-searcher!"](ModuleRollbackManager, package.loaders)
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
      local _24_, _25_ = nil, nil
      do
        local _27_, _28_ = fennel["search-module"](module_name, fennel.path)
        if (nil ~= _27_) then
          local fnl_path = _27_
          local _let_29_ = require("thyme.compiler.cache")
          local determine_lua_path = _let_29_["determine-lua-path"]
          local lua_path = determine_lua_path(module_name)
          local compiler_options = Config["compiler-options"]
          local _30_, _31_ = pcall_with_logger_21(fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
          if ((_30_ == true) and (nil ~= _31_)) then
            local lua_code = _31_
            if can_restore_file_3f(lua_path, lua_code) then
              restore_file_21(lua_path)
            else
              write_lua_file_with_backup_21(lua_path, lua_code, module_name)
              backup_handler["cleanup-old-backups!"](backup_handler, module_name)
            end
            _24_, _25_ = load(lua_code, lua_path)
          elseif (true and (nil ~= _31_)) then
            local _ = _30_
            local msg = _31_
            local msg_prefix = ("\n    thyme-loader: %s is found for the module %s, but failed to compile it\n    \t"):format(fnl_path, module_name)
            _24_, _25_ = nil, (msg_prefix .. msg)
          else
            _24_, _25_ = nil
          end
        elseif (true and (nil ~= _28_)) then
          local _ = _27_
          local msg = _28_
          _24_, _25_ = nil, ("\nthyme-loader: " .. msg)
        else
          _24_, _25_ = nil
        end
      end
      if (nil ~= _24_) then
        local chunk = _24_
        or_20_ = chunk
      elseif (true and (nil ~= _25_)) then
        local _ = _24_
        local error_msg = _25_
        local backup_path = backup_handler["determine-active-backup-path"](backup_handler, module_name)
        local max_rollbacks = Config["max-rollbacks"]
        local rollback_enabled_3f = (0 < max_rollbacks)
        if (rollback_enabled_3f and file_readable_3f(backup_path)) then
          local msg = ("thyme-rollback-loader: temporarily restore backup for the module %s (created at %s) due to the following error: %s\nHINT: You can reduce its annoying errors during repairing the module running `:ThymeRollbackMount` to keep the active backup in the next nvim session.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name), error_msg)
          vim.notify_once(msg, vim.log.levels.WARN)
          or_20_ = loadfile(backup_path)
        else
          or_20_ = error_msg
        end
      else
        or_20_ = nil
      end
    end
    return or_20_
  end
end
return {["search-fnl-module-on-rtp!"] = search_fnl_module_on_rtp_21, ["write-lua-file-with-backup!"] = write_lua_file_with_backup_21}
