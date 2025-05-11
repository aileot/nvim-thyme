local fennel = require("fennel")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local Messenger = require("thyme.utils.messenger")
local RecompilerMessenger = Messenger.new("watch/recompiler")
local Config = require("thyme.config")
local _local_2_ = require("thyme.wrapper.fennel")
local compile_file = _local_2_["compile-file"]
local _local_3_ = require("thyme.module-map.callstack")
local observe_21 = _local_3_["observe!"]
local _local_4_ = require("thyme.module-map.logger")
local fnl_path__3elua_path = _local_4_["fnl-path->lua-path"]
local fnl_path__3eentry_map = _local_4_["fnl-path->entry-map"]
local fnl_path__3edependent_map = _local_4_["fnl-path->dependent-map"]
local clear_module_map_21 = _local_4_["clear-module-map!"]
local restore_module_map_21 = _local_4_["restore-module-map!"]
local _local_5_ = require("thyme.searcher.module")
local write_lua_file_with_backup_21 = _local_5_["write-lua-file-with-backup!"]
local _local_6_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_6_["clear-cache!"]
local default_strategy = "recompile"
local function fnl_path__3edependent_count(fnl_path)
  local _7_ = fnl_path__3edependent_map(fnl_path)
  if (nil ~= _7_) then
    local dependent_map = _7_
    local i = 0
    for _ in pairs(dependent_map) do
      i = i
    end
    return i
  else
    local _ = _7_
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
  local _9_, _10_ = observe_21(fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_9_ == true) and (nil ~= _10_)) then
    local lua_code = _10_
    local msg = ("successfully recompile " .. fnl_path)
    write_lua_file_with_backup_21(lua_path, lua_code, module_name)
    RecompilerMessenger["notify!"](RecompilerMessenger, msg)
    return true
  elseif (true and (nil ~= _10_)) then
    local _ = _9_
    local error_msg = _10_
    local msg = ("abort recompiling %s due to the following error:\n%s"):format(fnl_path, error_msg)
    RecompilerMessenger["notify!"](RecompilerMessenger, msg, vim.log.levels.WARN)
    restore_module_map_21(fnl_path)
    return false
  else
    return nil
  end
end
local function update_module_dependencies_21(fnl_path, _3flua_path, opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/check.fnl:60")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/user/check.fnl:60")
  local always_recompile_3f = opts["_always-recompile?"]
  local strategy = (opts._strategy or error("no strategy is specified"))
  local _let_12_ = fnl_path__3eentry_map(fnl_path)
  local module_name = _let_12_["module-name"]
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
    local _17_ = fnl_path__3edependent_map(fnl_path)
    if (nil ~= _17_) then
      local dependent_map = _17_
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
  local _20_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _20_) then
    local modmap = _20_
    local dependent_count = fnl_path__3edependent_count(fnl_path)
    local user_strategy
    do
      local _21_ = type(opts.strategy)
      if (_21_ == "string") then
        user_strategy = opts.strategy
      elseif (_21_ == "function") then
        local context = {["module-name"] = modmap["module-name"]}
        user_strategy = opts.strategy(dependent_count, context)
      elseif (_21_ == "nil") then
        user_strategy = default_strategy
      elseif (nil ~= _21_) then
        local _else = _21_
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
