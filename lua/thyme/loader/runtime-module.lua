local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local Path = require("thyme.util.path")
local _local_2_ = require("thyme.util.fs")
local executable_3f = _local_2_["executable?"]
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local read_file = _local_2_["read-file"]
local write_lua_file_21 = _local_2_["write-lua-file!"]
local fs = _local_2_
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
local _local_6_ = require("thyme.loader.macro-module")
local initialize_macro_searcher_on_rtp_21 = _local_6_["initialize-macro-searcher-on-rtp!"]
local RollbackManager = require("thyme.rollback.manager")
local RuntimeModuleRollbackManager = RollbackManager.new("runtime", ".lua")
local cache = {rtp = nil}
local function compile_fennel_into_rtp_21(fennel_repo_path)
  local fennel_lua_file = "fennel.lua"
  local _let_7_ = vim.fs.find("Makefile", {upward = true, path = fennel_repo_path})
  local fennel_src_Makefile = _let_7_[1]
  local _ = assert(fennel_src_Makefile, "Could not find Makefile for fennel.lua.")
  local fennel_src_root = vim.fs.dirname(fennel_src_Makefile)
  local _3flua
  if executable_3f("luajit") then
    _3flua = "luajit"
  elseif executable_3f("lua") then
    local stdout = vim.system({"lua", "-v"}, {text = true}):wait().stdout
    if (stdout:find("^LuaJIT") or stdout:find("^Lua 5%.1%.")) then
      _3flua = "lua"
    else
      _3flua = nil
    end
  else
    _3flua = nil
  end
  local LUA = (_3flua or "nvim --clean --headless -l")
  local env = {LUA = LUA}
  local on_exit
  local function _10_(out)
    return assert((0 == tonumber(out.code)), ("failed to compile fennel.lua with code: %s\n%s"):format(out.code, out.stderr))
  end
  on_exit = _10_
  local make_cmd = {"make", "-C", fennel_src_root, fennel_lua_file}
  local fennel_lua_path = Path.join(fennel_src_root, fennel_lua_file)
  vim.system(make_cmd, {text = true, env = env}, on_exit):wait()
  return fennel_lua_path
end
local function locate_fennel_path_21()
  local _12_
  do
    local _11_ = vim.api.nvim_get_runtime_file("fennel.lua", false)
    if ((_G.type(_11_) == "table") and (nil ~= _11_[1])) then
      local fennel_lua_path = _11_[1]
      _12_ = fennel_lua_path
    elseif ((_G.type(_11_) == "table") and (_11_[1] == nil)) then
      _12_ = false
    else
      _12_ = nil
    end
  end
  local or_16_ = _12_
  if not or_16_ then
    local _17_ = vim.api.nvim_get_runtime_file("fennel", false)
    if ((_G.type(_17_) == "table") and (nil ~= _17_[1])) then
      local fennel_lua_path = _17_[1]
      or_16_ = fennel_lua_path
    elseif ((_G.type(_17_) == "table") and (_17_[1] == nil)) then
      or_16_ = false
    else
      or_16_ = nil
    end
  end
  if not or_16_ then
    local rtp = vim.api.nvim_get_option_value("rtp", {})
    local _23_ = (rtp:match(Path.join("([^,]+", "fennel),")) or rtp:match(Path.join("([^,]+", "fennel)$")))
    if (nil ~= _23_) then
      local fennel_repo_path = _23_
      or_16_ = compile_fennel_into_rtp_21(fennel_repo_path)
    else
      local _ = _23_
      if executable_3f("fennel") then
        or_16_ = vim.fn.exepath("fennel")
      else
        or_16_ = error("please make sure to add the path to fennel repo in `&runtimepath`")
      end
    end
  end
  return or_16_
end
local function cache_fennel_lua_21(fennel_lua_path)
  assert_is_file_readable(fennel_lua_path)
  local fennel_lua_file = "fennel.lua"
  local cached_fennel_path = Path.join(lua_cache_prefix, fennel_lua_file)
  if not (cached_fennel_path == fennel_lua_path) then
    vim.fn.mkdir(vim.fs.dirname(cached_fennel_path), "p")
    if can_restore_file_3f(cached_fennel_path, read_file(fennel_lua_path)) then
      restore_file_21(cached_fennel_path)
    else
      fs.copyfile(fennel_lua_path, cached_fennel_path)
    end
    assert_is_file_readable(cached_fennel_path)
  else
  end
  return cached_fennel_path
end
local function load_fennel(fennel_lua_path)
  local cached_fennel_path = cache_fennel_lua_21(fennel_lua_path)
  return assert(loadfile(cached_fennel_path))
end
local function initialize_module_searcher_on_rtp_21(fennel)
  local std_config_home = vim.fn.stdpath("config")
  local Config = require("thyme.config")
  local fnl_dir = string.gsub(("/" .. Config["fnl-dir"] .. "/"), "//+", "/")
  local fennel_path
  local _31_
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
    _31_ = tbl_21_
  end
  fennel_path = table.concat(_31_, ";")
  fennel.path = fennel_path
  return nil
end
local function update_fennel_paths_21(fennel)
  local Config = require("thyme.config")
  local base_path_cache
  local function _33_(self, key)
    rawset(self, key, get_runtime_files({key}, true))
    return self[key]
  end
  base_path_cache = setmetatable({}, {__index = _33_})
  local macro_path
  local _34_
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
        local _35_
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
          _35_ = tbl_21_0
        end
        val_23_ = table.concat(_35_, ";")
      end
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _34_ = tbl_21_
  end
  macro_path = table.concat(_34_, ";"):gsub("/%./", "/")
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
  if module_name:find("^vim%.") then
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
      local function _42_(path, ...)
        return loadfile(path)
      end
      file_loader = _42_
      local _44_
      do
        local _43_
        do
          local _45_ = RuntimeModuleRollbackManager["inject-mounted-backup-searcher!"](RuntimeModuleRollbackManager, package.loaders, file_loader)
          if (nil ~= _45_) then
            local searcher = _45_
            _43_ = searcher(module_name)
          else
            _43_ = nil
          end
        end
        if (nil ~= _43_) then
          local msg_7cchunk = _43_
          local _48_ = type(msg_7cchunk)
          if (_48_ == "function") then
            _44_ = msg_7cchunk
          else
            _44_ = nil
          end
        else
          _44_ = nil
        end
      end
      local or_53_ = _44_
      if not or_53_ then
        local _54_, _55_ = nil, nil
        do
          local _57_, _58_ = module_name__3efnl_file_on_rtp_21(module_name)
          if (nil ~= _57_) then
            local fnl_path = _57_
            local fennel = require("fennel")
            local _let_59_ = require("thyme.compiler.cache")
            local determine_lua_path = _let_59_["determine-lua-path"]
            local lua_path = determine_lua_path(module_name)
            local compiler_options = Config["compiler-options"]
            local _60_, _61_ = Observer["observe!"](Observer, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
            if ((_60_ == true) and (nil ~= _61_)) then
              local lua_code = _61_
              if can_restore_file_3f(lua_path, lua_code) then
                restore_file_21(lua_path)
              else
                write_lua_file_with_backup_21(lua_path, lua_code, module_name)
                backup_handler["cleanup-old-backups!"](backup_handler)
              end
              _54_, _55_ = load(lua_code, lua_path)
            elseif (true and (nil ~= _61_)) then
              local _ = _60_
              local raw_msg = _61_
              local raw_msg_body = ("%s is found for the runtime/%s, but failed to compile it"):format(fnl_path, module_name)
              local msg = LoaderMessenger["mk-failure-reason"](LoaderMessenger, ("%s\n\9%s"):format(raw_msg_body, raw_msg))
              _54_, _55_ = nil, msg
            else
              _54_, _55_ = nil
            end
          elseif (true and (nil ~= _58_)) then
            local _ = _57_
            local raw_msg = _58_
            _54_, _55_ = nil, raw_msg
          else
            _54_, _55_ = nil
          end
        end
        if (nil ~= _54_) then
          local chunk = _54_
          or_53_ = chunk
        elseif (true and (nil ~= _55_)) then
          local _ = _54_
          local error_msg = _55_
          local backup_path = backup_handler["determine-active-backup-path"](backup_handler, module_name)
          local max_rollbacks = Config["max-rollbacks"]
          local rollback_enabled_3f = (0 < max_rollbacks)
          if (rollback_enabled_3f and file_readable_3f(backup_path)) then
            local msg = ("temporarily restore backup for the module/%s (created at %s) due to the following error:\n%s\n\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_53_ = loadfile(backup_path)
          else
            or_53_ = LoaderMessenger["mk-failure-reason"](LoaderMessenger, error_msg)
          end
        else
          or_53_ = nil
        end
      end
      return or_53_
    end
  end
end
return {["search-fnl-module-on-rtp!"] = search_fnl_module_on_rtp_21, ["write-lua-file-with-backup!"] = write_lua_file_with_backup_21, RuntimeModuleRollbackManager = RuntimeModuleRollbackManager}
