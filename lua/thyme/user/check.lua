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
local function recompile_21(fnl_path, lua_path)
  local config = get_main_config()
  local compiler_options = config["compiler-options"]
  local _let_7_ = fnl_path__3eentry_map(fnl_path)
  local module_name = _let_7_["module-name"]
  compiler_options["module-name"] = module_name
  clear_module_map_21(fnl_path)
  local _8_, _9_ = pcall_with_logger_21(fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_8_ == true) and (nil ~= _9_)) then
    local lua_code = _9_
    return write_lua_file_with_backup_21(lua_path, lua_code, module_name)
  elseif (true and (nil ~= _9_)) then
    local _ = _8_
    local error_msg = _9_
    local msg = ("thyme-recompiler: abort recompiling %s due to the following error\n%s"):format(fnl_path, error_msg)
    vim.notify(msg, vim.log.levels.WARN)
    return restore_module_map_21(fnl_path)
  else
    return nil
  end
end
local function update_module_dependencies_21(fnl_path, _3flua_path_to_clear, opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/thyme/user/check.fnl:43")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/user/check.fnl:43")
  do
    local _11_ = fnl_path__3edependent_map(fnl_path)
    if (nil ~= _11_) then
      local dependent_map = _11_
      for dependent_fnl_path, dependent in pairs(dependent_map) do
        if not (fnl_path == dependent_fnl_path) then
          update_module_dependencies_21(dependent_fnl_path, dependent["lua-path"], opts)
        else
        end
      end
    else
    end
  end
  local should_recompile_lua_cache_3f = (_3flua_path_to_clear and (not file_readable_3f(_3flua_path_to_clear) or (read_file(_3flua_path_to_clear) ~= compile_file(fnl_path))))
  if should_recompile_lua_cache_3f then
    return recompile_21(fnl_path)
  else
    return nil
  end
end
local function check_to_update_21(fnl_path, _3fopts)
  local opts = (_3fopts or {})
  local lua_path = fnl_path__3elua_path(fnl_path)
  return update_module_dependencies_21(fnl_path, lua_path, opts)
end
return {["check-to-update!"] = check_to_update_21}
