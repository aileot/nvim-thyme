local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local Path = require("thyme.utils.path")
local _local_2_ = require("thyme.utils.fs")
local executable_3f = _local_2_["executable?"]
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
local Messenger = require("thyme.utils.messenger")
local LoaderMessenger = Messenger.new("loader")
local RollbackLoaderMessenger = Messenger.new("loader/rollback")
local _local_5_ = require("thyme.wrapper.nvim")
local get_runtime_files = _local_5_["get-runtime-files"]
local Observer = require("thyme.dependency.observer")
local _local_6_ = require("thyme.searcher.macro")
local initialize_macro_searcher_on_rtp_21 = _local_6_["initialize-macro-searcher-on-rtp!"]
local RollbackManager = require("thyme.rollback.manager")
local ModuleRollbackManager = RollbackManager.new("module", ".lua")
local cache = {rtp = nil}
local function compile_fennel_into_rtp_21()
  local rtp = vim.api.nvim_get_option_value("rtp", {})
  local fnl_src_path = (rtp:match(Path.join("([^,]+", "fennel),")) or rtp:match(Path.join("([^,]+", "fennel)$")) or error("please make sure to add the path to fennel repo in `&runtimepath`"))
  local fennel_lua_file = "fennel.lua"
  local cached_fennel_path = Path.join(lua_cache_prefix, fennel_lua_file)
  local _let_7_ = vim.fs.find("Makefile", {upward = true, path = fnl_src_path})
  local fennel_src_Makefile = _let_7_[1]
  local _ = assert(fennel_src_Makefile, "Could not find Makefile for fennel.lua.")
  local fennel_src_root = vim.fs.dirname(fennel_src_Makefile)
  local fennel_lua_path = Path.join(fennel_src_root, fennel_lua_file)
  do
    local on_exit
    local function _8_(out)
      return assert((0 == tonumber(out.code)), ("failed to compile fennel.lua with code: %s\n%s"):format(out.code, out.stderr))
    end
    on_exit = _8_
    local LUA
    if not executable_3f("lua") then
      LUA = (vim.env.LUA or "nvim --clean --headless -l")
    else
      LUA = nil
    end
    local env = {LUA = LUA}
    local make_cmd = {"make", "-C", fennel_src_root, fennel_lua_file}
    vim.system(make_cmd, {text = true, env = env}, on_exit):wait()
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
  local Config = require("thyme.config")
  local fnl_dir = string.gsub(("/" .. Config["fnl-dir"] .. "/"), "//+", "/")
  local fennel_path
  local _11_
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
    _11_ = tbl_21_
  end
  fennel_path = table.concat(_11_, ";")
  fennel.path = fennel_path
  return nil
end
local function update_fennel_paths_21(fennel)
  local Config = require("thyme.config")
  local base_path_cache
  local function _13_(self, key)
    rawset(self, key, get_runtime_files({key}, true))
    return self[key]
  end
  base_path_cache = setmetatable({}, {__index = _13_})
  local macro_path
  local _14_
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
        local _15_
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
          _15_ = tbl_21_0
        end
        val_23_ = table.concat(_15_, ";")
      end
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _14_ = tbl_21_
  end
  macro_path = table.concat(_14_, ";"):gsub("/%./", "/")
  fennel["macro-path"] = macro_path
  return nil
end
local function write_lua_file_with_backup_21(lua_path, lua_code, module_name)
  write_lua_file_21(lua_path, lua_code)
  local backup_handler = ModuleRollbackManager["backup-handler-of"](ModuleRollbackManager, module_name)
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
  if ("fennel" == module_name) then
    return compile_fennel_into_rtp_21()
  else
    local Config = require("thyme.config")
    local or_22_ = Config["?error-msg"]
    if not or_22_ then
      local backup_handler = ModuleRollbackManager["backup-handler-of"](ModuleRollbackManager, module_name)
      local _3fchunk
      do
        local _24_
        do
          local _25_
          do
            local file_loader
            local function _26_(path, ...)
              return loadfile(path)
            end
            file_loader = _26_
            _25_ = ModuleRollbackManager["inject-mounted-backup-searcher!"](ModuleRollbackManager, package.loaders, file_loader)
          end
          if (nil ~= _25_) then
            local searcher = _25_
            _24_ = searcher(module_name)
          else
            _24_ = nil
          end
        end
        if (nil ~= _24_) then
          local msg_7cchunk = _24_
          local _28_ = type(msg_7cchunk)
          if (_28_ == "function") then
            _3fchunk = msg_7cchunk
          else
            _3fchunk = nil
          end
        else
          _3fchunk = nil
        end
      end
      local or_31_ = _3fchunk
      if not or_31_ then
        local _32_, _33_ = nil, nil
        do
          local _35_, _36_ = module_name__3efnl_file_on_rtp_21(module_name)
          if (nil ~= _35_) then
            local fnl_path = _35_
            local fennel = require("fennel")
            local _let_37_ = require("thyme.compiler.cache")
            local determine_lua_path = _let_37_["determine-lua-path"]
            local lua_path = determine_lua_path(module_name)
            local compiler_options = Config["compiler-options"]
            local _38_, _39_ = Observer["observe!"](Observer, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
            if ((_38_ == true) and (nil ~= _39_)) then
              local lua_code = _39_
              if can_restore_file_3f(lua_path, lua_code) then
                restore_file_21(lua_path)
              else
                write_lua_file_with_backup_21(lua_path, lua_code, module_name)
                backup_handler["cleanup-old-backups!"](backup_handler)
              end
              _32_, _33_ = load(lua_code, lua_path)
            elseif (true and (nil ~= _39_)) then
              local _ = _38_
              local raw_msg = _39_
              local raw_msg_body = ("%s is found for the module/%s, but failed to compile it"):format(fnl_path, module_name)
              local msg_body = LoaderMessenger["wrap-msg"](LoaderMessenger, raw_msg_body)
              local msg = ("\n%s\n\9%s"):format(msg_body, raw_msg)
              _32_, _33_ = nil, msg
            else
              _32_, _33_ = nil
            end
          elseif (true and (nil ~= _36_)) then
            local _ = _35_
            local raw_msg = _36_
            local msg = LoaderMessenger["wrap-msg"](LoaderMessenger, raw_msg)
            _32_, _33_ = nil, ("\n" .. msg)
          else
            _32_, _33_ = nil
          end
        end
        if (nil ~= _32_) then
          local chunk = _32_
          or_31_ = chunk
        elseif (true and (nil ~= _33_)) then
          local _ = _32_
          local error_msg = _33_
          local backup_path = backup_handler["determine-active-backup-path"](backup_handler, module_name)
          local max_rollbacks = Config["max-rollbacks"]
          local rollback_enabled_3f = (0 < max_rollbacks)
          if (rollback_enabled_3f and file_readable_3f(backup_path)) then
            local msg = ("temporarily restore backup for the module/%s (created at %s) due to the following error: %s\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_31_ = loadfile(backup_path)
          else
            or_31_ = error_msg
          end
        else
          or_31_ = nil
        end
      end
      or_22_ = or_31_
    end
    return or_22_
  end
end
return {["search-fnl-module-on-rtp!"] = search_fnl_module_on_rtp_21, ["write-lua-file-with-backup!"] = write_lua_file_with_backup_21}
