local fennel = require("fennel")
local _local_1_ = require("thyme.utils.general")
local do_nothing = _local_1_["do-nothing"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local read_file = _local_2_["read-file"]
local _local_3_ = require("thyme.config")
local get_main_config = _local_3_["get-main-config"]
local _local_4_ = require("thyme.wrapper.fennel")
local compile_file = _local_4_["compile-file"]
local _local_5_ = require("thyme.module-map.callstack")
local pcall_with_logger_21 = _local_5_["pcall-with-logger!"]
local _local_6_ = require("thyme.module-map.logger")
local fnl_path__3elua_path = _local_6_["fnl-path->lua-path"]
local fnl_path__3eentry_map = _local_6_["fnl-path->entry-map"]
local fnl_path__3edependent_map = _local_6_["fnl-path->dependent-map"]
local clear_module_map_21 = _local_6_["clear-module-map!"]
local restore_module_map_21 = _local_6_["restore-module-map!"]
local _local_7_ = require("thyme.searcher.module")
local write_lua_file_with_backup_21 = _local_7_["write-lua-file-with-backup!"]
local default_strategy = "recompile"
local function fnl_path__3edependent_count(fnl_path)
  local _8_ = fnl_path__3edependent_map(fnl_path)
  if (nil ~= _8_) then
    local dependent_map = _8_
    local i = 0
    for _, _0 in pairs(dependent_map) do
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
  local config = get_main_config()
  local compiler_options = config["compiler-options"]
  compiler_options["module-name"] = module_name
  clear_module_map_21(fnl_path)
  local _10_, _11_ = pcall_with_logger_21(fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_10_ == true) and (nil ~= _11_)) then
    local lua_code = _11_
    write_lua_file_with_backup_21(lua_path, lua_code, module_name)
    return true
  elseif (true and (nil ~= _11_)) then
    local _ = _10_
    local error_msg = _11_
    local msg = ("thyme-recompiler: abort recompiling %s due to the following error\n  %s"):format(fnl_path, error_msg)
    vim.notify(msg, vim.log.levels.WARN)
    restore_module_map_21(fnl_path)
    return false
  else
    return nil
  end
end
local function update_module_dependencies_21(fnl_path, _3flua_path, opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/check.fnl:59")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/user/check.fnl:59")
  local strategy = (opts._strategy or error("no strategy is specified"))
  local _let_13_ = fnl_path__3eentry_map(fnl_path)
  local module_name = _let_13_["module-name"]
  local notifiers = (opts.notifier or {})
  if _3flua_path then
    if (strategy == "always-recompile") then
      local ok_3f = recompile_21(fnl_path, _3flua_path, module_name)
      if (ok_3f and notifiers.recompile) then
        notifiers.recompile(("[thyme] successfully recompile " .. fnl_path))
      else
      end
    elseif (strategy == "recompile") then
      if should_recompile_lua_cache_3f(fnl_path, _3flua_path) then
        local ok_3f = recompile_21(fnl_path, _3flua_path, module_name)
        if (ok_3f and notifiers.recompile) then
          notifiers.recompile(("[thyme] successfully recompile " .. fnl_path))
        else
        end
      else
      end
    else
    end
  else
  end
  if ((strategy == "recompile") or (strategy == "reload") or (strategy == "always-recompile") or (strategy == "always-reload")) then
    local _19_ = fnl_path__3edependent_map(fnl_path)
    if (nil ~= _19_) then
      local dependent_map = _19_
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
  local _22_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _22_) then
    local modmap = _22_
    local dependent_count = fnl_path__3edependent_count(fnl_path)
    local strategy
    do
      local _23_ = type(opts.strategy)
      if (_23_ == "string") then
        strategy = opts.strategy
      elseif (_23_ == "function") then
        local context = {["module-name"] = modmap["module-name"]}
        strategy = opts.strategy(dependent_count, context)
      elseif (_23_ == "nil") then
        strategy = default_strategy
      elseif (nil ~= _23_) then
        local _else = _23_
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
