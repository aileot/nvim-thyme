local fennel = require("fennel")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local read_file = _local_2_["read-file"]
local Messenger = require("thyme.utils.messenger")
local RecompilerMessenger = Messenger.new("check.recompiler")
local Config = require("thyme.config")
local _local_3_ = require("thyme.wrapper.fennel")
local compile_file = _local_3_["compile-file"]
local _local_4_ = require("thyme.module-map.callstack")
local pcall_with_logger_21 = _local_4_["pcall-with-logger!"]
local _local_5_ = require("thyme.module-map.logger")
local fnl_path__3elua_path = _local_5_["fnl-path->lua-path"]
local fnl_path__3eentry_map = _local_5_["fnl-path->entry-map"]
local fnl_path__3edependent_map = _local_5_["fnl-path->dependent-map"]
local clear_module_map_21 = _local_5_["clear-module-map!"]
local restore_module_map_21 = _local_5_["restore-module-map!"]
local _local_6_ = require("thyme.searcher.module")
local write_lua_file_with_backup_21 = _local_6_["write-lua-file-with-backup!"]
local _local_7_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_7_["clear-cache!"]
local default_strategy = "recompile"
local function fnl_path__3edependent_count(fnl_path)
  local _8_ = fnl_path__3edependent_map(fnl_path)
  if (nil ~= _8_) then
    local dependent_map = _8_
    local i = 0
    for _ in pairs(dependent_map) do
      i = i
    end
    return i
  else
    local _ = _8_
    return 0
  end
end
local function should_recompile_lua_cache_3f(fnl_path, _3flua_path)
  return (_3flua_path and (not file_readable_3f(_3flua_path) or (read_file(_3flua_path) ~= compile_file(fnl_path))))
end
local function recompile_21(fnl_path, lua_path, module_name)
  local compiler_options = Config["compiler-options"]
  compiler_options["module-name"] = module_name
  clear_module_map_21(fnl_path)
  local _10_, _11_ = pcall_with_logger_21(fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_10_ == true) and (nil ~= _11_)) then
    local lua_code = _11_
    local msg = ("successfully recompile " .. fnl_path)
    write_lua_file_with_backup_21(lua_path, lua_code, module_name)
    RecompilerMessenger["notify!"](RecompilerMessenger, msg)
    return true
  elseif (true and (nil ~= _11_)) then
    local _ = _10_
    local error_msg = _11_
    local msg = ("abort recompiling %s due to the following error:\n%s"):format(fnl_path, error_msg)
    RecompilerMessenger["notify!"](RecompilerMessenger, msg, vim.log.levels.WARN)
    restore_module_map_21(fnl_path)
    return false
  else
    return nil
  end
end
local function update_module_dependencies_21(fnl_path, _3flua_path, opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/check.fnl:61")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/user/check.fnl:61")
  local always_recompile_3f = opts["_always-recompile?"]
  local strategy = (opts._strategy or error("no strategy is specified"))
  local _let_13_ = fnl_path__3eentry_map(fnl_path)
  local module_name = _let_13_["module-name"]
  if _3flua_path then
    if (strategy == "clear-all") then
      if (always_recompile_3f or should_recompile_lua_cache_3f(fnl_path, _3flua_path)) then
        clear_cache_21()
      else
      end
    elseif (strategy == "recompile") then
      if (always_recompile_3f or should_recompile_lua_cache_3f(fnl_path, _3flua_path)) then
        recompile_21(fnl_path, _3flua_path, module_name)
      else
      end
    else
    end
  else
  end
  if ((strategy == "clear-all") or (strategy == "clear") or (strategy == "recompile") or (strategy == "reload")) then
    local _18_ = fnl_path__3edependent_map(fnl_path)
    if (nil ~= _18_) then
      local dependent_map = _18_
      for dependent_fnl_path, dependent in pairs(dependent_map) do
        update_module_dependencies_21(dependent_fnl_path, dependent["lua-path"], opts)
      end
      return nil
    else
      return nil
    end
  else
    local _ = strategy
    return error(("unsupported strategy: " .. strategy))
  end
end
local function check_to_update_21(fnl_path, _3fopts)
  local opts = (_3fopts or {})
  local lua_path = fnl_path__3elua_path(fnl_path)
  local _21_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _21_) then
    local modmap = _21_
    local dependent_count = fnl_path__3edependent_count(fnl_path)
    local user_strategy
    do
      local _22_ = type(opts.strategy)
      if (_22_ == "string") then
        user_strategy = opts.strategy
      elseif (_22_ == "function") then
        local context = {["module-name"] = modmap["module-name"]}
        user_strategy = opts.strategy(dependent_count, context)
      elseif (_22_ == "nil") then
        user_strategy = default_strategy
      elseif (nil ~= _22_) then
        local _else = _22_
        user_strategy = error(("expected string or function, got " .. _else))
      else
        user_strategy = nil
      end
    end
    local always_prefix = "always-"
    local always_prefix_length = #always_prefix
    local always_recompile_3f = (always_prefix == user_strategy:sub(1, always_prefix_length))
    local strategy
    if always_recompile_3f then
      strategy = user_strategy:sub((always_prefix_length + 1))
    else
      strategy = user_strategy
    end
    opts["_always-recompile?"] = always_recompile_3f
    opts._strategy = strategy
    update_module_dependencies_21(fnl_path, lua_path, opts)
    opts._strategy = nil
    return nil
  else
    return nil
  end
end
return {["check-to-update!"] = check_to_update_21}
