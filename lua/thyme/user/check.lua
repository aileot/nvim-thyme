local fennel = require("fennel")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local Messenger = require("thyme.utils.messenger")
local RecompilerMessenger = Messenger.new("watch/recompiler")
local Config = require("thyme.config")
local _local_2_ = require("thyme.wrapper.fennel")
local compile_file = _local_2_["compile-file"]
local Observer = require("thyme.dependency.observer")
local DependencyLogger = require("thyme.dependency.logger")
local _local_3_ = require("thyme.searcher.module")
local write_lua_file_with_backup_21 = _local_3_["write-lua-file-with-backup!"]
local _local_4_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_4_["clear-cache!"]
local default_strategy = "recompile"
local function fnl_path__3edependent_count(fnl_path)
  local _5_ = DependencyLogger["fnl-path->dependent-maps"](DependencyLogger, fnl_path)
  if (nil ~= _5_) then
    local dependent_maps = _5_
    local i = 0
    for _ in pairs(dependent_maps) do
      i = i
    end
    return i
  else
    local _ = _5_
    return 0
  end
end
local function should_recompile_lua_cache_3f(fnl_path, _3flua_path)
  return (_3flua_path and (not file_readable_3f(_3flua_path) or (read_file(_3flua_path) ~= compile_file(fnl_path))))
end
local function recompile_21(fnl_path, lua_path, module_name)
  local compiler_options = Config["compiler-options"]
  compiler_options["module-name"] = module_name
  DependencyLogger["clear-module-map!"](DependencyLogger, fnl_path)
  local _7_, _8_ = Observer["observe!"](Observer, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_7_ == true) and (nil ~= _8_)) then
    local lua_code = _8_
    local msg = ("successfully recompile " .. fnl_path)
    write_lua_file_with_backup_21(lua_path, lua_code, module_name)
    RecompilerMessenger["notify!"](RecompilerMessenger, msg)
    return true
  elseif (true and (nil ~= _8_)) then
    local _ = _7_
    local error_msg = _8_
    local msg = ("abort recompiling %s due to the following error:\n%s"):format(fnl_path, error_msg)
    RecompilerMessenger["notify!"](RecompilerMessenger, msg, vim.log.levels.WARN)
    DependencyLogger["restore-module-map!"](DependencyLogger, fnl_path)
    return false
  else
    return nil
  end
end
local function update_module_dependencies_21(fnl_path, _3flua_path, opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/check.fnl:57")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/user/check.fnl:57")
  local always_recompile_3f = opts["_always-recompile?"]
  local strategy = (opts._strategy or error("no strategy is specified"))
  local module_name = DependencyLogger["fnl-path->module-name"](DependencyLogger, fnl_path)
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
    local _14_ = DependencyLogger["fnl-path->dependent-maps"](DependencyLogger, fnl_path)
    if (nil ~= _14_) then
      local dependent_maps = _14_
      for dependent_fnl_path, dependent in pairs(dependent_maps) do
        local function _15_()
          return update_module_dependencies_21(dependent_fnl_path, dependent["lua-path"], opts)
        end
        vim.schedule(_15_)
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
  local lua_path = DependencyLogger["fnl-path->lua-path"](DependencyLogger, fnl_path)
  local _18_ = DependencyLogger["fnl-path->module-name"](DependencyLogger, fnl_path)
  if (nil ~= _18_) then
    local module_name = _18_
    local dependent_count = fnl_path__3edependent_count(fnl_path)
    local user_strategy
    do
      local _19_ = type(opts.strategy)
      if (_19_ == "string") then
        user_strategy = opts.strategy
      elseif (_19_ == "function") then
        local context = {["module-name"] = module_name}
        user_strategy = opts.strategy(dependent_count, context)
      elseif (_19_ == "nil") then
        user_strategy = default_strategy
      elseif (nil ~= _19_) then
        local _else = _19_
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
    return update_module_dependencies_21(fnl_path, lua_path, opts)
  else
    return nil
  end
end
return {["check-to-update!"] = check_to_update_21}
