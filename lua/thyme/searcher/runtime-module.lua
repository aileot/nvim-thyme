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
local _local_6_ = require("thyme.searcher.macro-module")
local initialize_macro_searcher_on_rtp_21 = _local_6_["initialize-macro-searcher-on-rtp!"]
local RollbackManager = require("thyme.rollback.manager")
local RuntimeModuleRollbackManager = RollbackManager.new("runtime", ".lua")
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
  local _12_
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
    _12_ = tbl_21_
  end
  fennel_path = table.concat(_12_, ";")
  fennel.path = fennel_path
  return nil
end
local function update_fennel_paths_21(fennel)
  local Config = require("thyme.config")
  local base_path_cache
  local function _14_(self, key)
    rawset(self, key, get_runtime_files({key}, true))
    return self[key]
  end
  base_path_cache = setmetatable({}, {__index = _14_})
  local macro_path
  local _15_
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
        local _16_
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
          _16_ = tbl_21_0
        end
        val_23_ = table.concat(_16_, ";")
      end
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _15_ = tbl_21_
  end
  macro_path = table.concat(_15_, ";"):gsub("/%./", "/")
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
    return compile_fennel_into_rtp_21()
  else
    local Config = require("thyme.config")
    local or_23_ = Config["?error-msg"]
    if not or_23_ then
      local backup_handler = RuntimeModuleRollbackManager["backup-handler-of"](RuntimeModuleRollbackManager, module_name)
      local _3fchunk
      do
        local _25_
        do
          local _26_
          do
            local file_loader
            local function _27_(path, ...)
              return loadfile(path)
            end
            file_loader = _27_
            _26_ = RuntimeModuleRollbackManager["inject-mounted-backup-searcher!"](RuntimeModuleRollbackManager, package.loaders, file_loader)
          end
          if (nil ~= _26_) then
            local searcher = _26_
            _25_ = searcher(module_name)
          else
            _25_ = nil
          end
        end
        if (nil ~= _25_) then
          local msg_7cchunk = _25_
          local _29_ = type(msg_7cchunk)
          if (_29_ == "function") then
            _3fchunk = msg_7cchunk
          else
            _3fchunk = nil
          end
        else
          _3fchunk = nil
        end
      end
      local or_32_ = _3fchunk
      if not or_32_ then
        local _33_, _34_ = nil, nil
        do
          local _36_, _37_ = module_name__3efnl_file_on_rtp_21(module_name)
          if (nil ~= _36_) then
            local fnl_path = _36_
            local fennel = require("fennel")
            local _let_38_ = require("thyme.compiler.cache")
            local determine_lua_path = _let_38_["determine-lua-path"]
            local lua_path = determine_lua_path(module_name)
            local compiler_options = Config["compiler-options"]
            local _39_, _40_ = Observer["observe!"](Observer, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
            if ((_39_ == true) and (nil ~= _40_)) then
              local lua_code = _40_
              if can_restore_file_3f(lua_path, lua_code) then
                restore_file_21(lua_path)
              else
                write_lua_file_with_backup_21(lua_path, lua_code, module_name)
                backup_handler["cleanup-old-backups!"](backup_handler)
              end
              _33_, _34_ = load(lua_code, lua_path)
            elseif (true and (nil ~= _40_)) then
              local _ = _39_
              local raw_msg = _40_
              local raw_msg_body = ("%s is found for the runtime/%s, but failed to compile it"):format(fnl_path, module_name)
              local msg_body = LoaderMessenger["wrap-msg"](LoaderMessenger, raw_msg_body)
              local msg = ("\n%s\n\9%s"):format(msg_body, raw_msg)
              _33_, _34_ = nil, msg
            else
              _33_, _34_ = nil
            end
          elseif (true and (nil ~= _37_)) then
            local _ = _36_
            local raw_msg = _37_
            local msg = LoaderMessenger["wrap-msg"](LoaderMessenger, raw_msg)
            _33_, _34_ = nil, ("\n" .. msg)
          else
            _33_, _34_ = nil
          end
        end
        if (nil ~= _33_) then
          local chunk = _33_
          or_32_ = chunk
        elseif (true and (nil ~= _34_)) then
          local _ = _33_
          local error_msg = _34_
          local backup_path = backup_handler["determine-active-backup-path"](backup_handler, module_name)
          local max_rollbacks = Config["max-rollbacks"]
          local rollback_enabled_3f = (0 < max_rollbacks)
          if (rollback_enabled_3f and file_readable_3f(backup_path)) then
            local msg = ("temporarily restore backup for the module/%s (created at %s) due to the following error: %s\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name), error_msg)
            RollbackLoaderMessenger["notify-once!"](RollbackLoaderMessenger, msg, vim.log.levels.WARN)
            or_32_ = loadfile(backup_path)
          else
            or_32_ = error_msg
          end
        else
          or_32_ = nil
        end
      end
      or_23_ = or_32_
    end
    return or_23_
  end
end
return {["search-fnl-module-on-rtp!"] = search_fnl_module_on_rtp_21, ["write-lua-file-with-backup!"] = write_lua_file_with_backup_21}
