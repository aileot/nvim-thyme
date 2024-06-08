local fennel = require("fennel")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local _local_2_ = require("thyme.config")
local get_main_config = _local_2_["get-main-config"]
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
local default_strategy = "recompile"
local function fnl_path__3edependent_count(fnl_path)
  local _7_ = fnl_path__3edependent_map(fnl_path)
  if (nil ~= _7_) then
    local dependent_map = _7_
    local i = 0
    for _, _0 in pairs(dependent_map) do
      i = i
    end
    return i
  else
    local _ = _7_
    return 0
  end
end
local function recompile_21(fnl_path, lua_path, compiler_options, module_name)
  compiler_options["module-name"] = module_name
  clear_module_map_21(fnl_path)
  local _9_, _10_ = pcall_with_logger_21(fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_9_ == true) and (nil ~= _10_)) then
    local lua_code = _10_
    return write_lua_file_with_backup_21(lua_path, lua_code, module_name)
  elseif (true and (nil ~= _10_)) then
    local _ = _9_
    local error_msg = _10_
    local msg = ("thyme-recompiler: abort recompiling %s due to the following error\n%s"):format(fnl_path, error_msg)
    vim.notify(msg, vim.log.levels.WARN)
    return restore_module_map_21(fnl_path)
  else
    return nil
  end
end
local function update_module_dependencies_21(fnl_path, _3flua_path, opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/check.fnl:48")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/user/check.fnl:48")
  local config = get_main_config()
  local compiler_options = config["compiler-options"]
  local strategy = (opts._strategy or error("no strategy is specified"))
  local _let_12_ = fnl_path__3eentry_map(fnl_path)
  local module_name = _let_12_["module-name"]
  if _3flua_path then
    if (strategy == "always-recompile") then
      recompile_21(fnl_path, _3flua_path, compiler_options, module_name)
    elseif (strategy == "recompile") then
      local should_recompile_lua_cache_3f = (_3flua_path and (not file_readable_3f(_3flua_path) or (read_file(_3flua_path) ~= compile_file(fnl_path))))
      if should_recompile_lua_cache_3f then
        recompile_21(fnl_path, _3flua_path, compiler_options, module_name)
      else
      end
    else
    end
  else
  end
  if ((strategy == "recompile") or (strategy == "reload") or (strategy == "always-recompile") or (strategy == "always-reload")) then
    local _16_ = fnl_path__3edependent_map(fnl_path)
    if (nil ~= _16_) then
      local dependent_map = _16_
      for dependent_fnl_path, dependent in pairs(dependent_map) do
        update_module_dependencies_21(dependent_fnl_path, dependent["lua-path"], opts)
      end
      return nil
    else
      return nil
    end
  else
    local _ = strategy
    return error(("unsupported sstrategy: " .. strategy))
  end
end
local function check_to_update_21(fnl_path, _3fopts)
  local opts = (_3fopts or {})
  local lua_path = fnl_path__3elua_path(fnl_path)
  local _19_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _19_) then
    local modmap = _19_
    local dependent_count = fnl_path__3edependent_count(fnl_path)
    local strategy
    do
      local _20_ = type(opts.strategy)
      if (_20_ == "string") then
        strategy = opts.strategy
      elseif (_20_ == "function") then
        local context = {["module-name"] = modmap["module-name"]}
        strategy = opts.strategy(dependent_count, context)
      elseif (_20_ == "nil") then
        strategy = default_strategy
      elseif (nil ~= _20_) then
        local _else = _20_
        strategy = error(("expected string or function, got " .. _else))
      else
        strategy = nil
      end
    end
    opts._strategy = strategy
    update_module_dependencies_21(fnl_path, lua_path, opts)
    opts._strategy = nil
    return nil
  else
    return nil
  end
end
return {["check-to-update!"] = check_to_update_21}
