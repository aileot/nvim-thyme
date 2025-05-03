local fennel = require("fennel")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.config")
local get_config = _local_2_["get-config"]
local _local_3_ = require("thyme.utils.iterator")
local each_file = _local_3_["each-file"]
local _local_4_ = require("thyme.rollback")
local get_root_of_backup = _local_4_["get-root"]
local _local_5_ = require("thyme.utils.pool")
local get_root_of_pool = _local_5_["get-root"]
local _local_6_ = require("thyme.wrapper.nvim")
local get_runtime_files = _local_6_["get-runtime-files"]
local _local_7_ = require("thyme.module-map.format")
local macro_recorded_3f = _local_7_["macro-recorded?"]
local peek_module_name = _local_7_["peek-module-name"]
local peek_fnl_path = _local_7_["peek-fnl-path"]
local _local_8_ = require("thyme.module-map.unit")
local get_root_of_modmap = _local_8_["get-root"]
local report_start, report_info, report_ok, report_warn, report_error = nil, nil, nil, nil, nil
do
  local health = vim.health
  if health.start then
    report_start, report_info, report_ok, report_warn, report_error = health.start, health.info, health.ok, health.warn, health.error
  else
    report_start, report_info, report_ok, report_warn, report_error = health.report_start, health.report_info, health.report_ok, health.report_warn, health.report_error
  end
end
local function report_integrations()
  report_start("Thyme Integrations")
  do
    local reporter
    if (nil == vim.g.parinfer_loaded) then
      reporter = report_warn
    else
      reporter = report_ok
    end
    reporter(("vim.g.parinfer_loaded = " .. tostring(vim.g.parinfer_loaded)))
  end
  local dependency_files = {"parser/fennel.so"}
  for _, file in ipairs(dependency_files) do
    local _11_ = get_runtime_files({file}, false)
    if ((_G.type(_11_) == "table") and (nil ~= _11_[1])) then
      local path = _11_[1]
      report_ok(("%s is detected at %s."):format(file, path))
    else
      local _0 = _11_
      report_warn(("missing %s."):format(file))
    end
  end
  return nil
end
local function report_thyme_disk_info()
  report_start("Thyme Disk Info")
  report_info(("The path to .nvim-thyme.fnl:\t" .. config_path))
  report_info(("The root path of Lua cache:\t" .. lua_cache_prefix))
  report_info(("The root path of backups for rollback:\t" .. get_root_of_backup()))
  report_info(("The root path of module-mapping:\t" .. get_root_of_modmap()))
  return report_info(("The root path of pool:\t" .. get_root_of_pool()))
end
local function report_thyme_config()
  report_start("Thyme .nvim-thyme.fnl")
  local config = get_config()
  config.source = nil
  config["module-name"] = nil
  config.filename = nil
  return report_info(("The current config:\n" .. fennel.view(config)))
end
local function report_fennel_paths()
  report_start("Thyme fennel.{path,macro-path}")
  report_info(("fennel.path:\n- " .. fennel.path:gsub(";", "\n- ")))
  return report_info(("fennel.macro-path:\n- " .. fennel["macro-path"]:gsub(";", "\n- ")))
end
local function report_imported_macros()
  report_start("Thyme Imported Macros")
  local root = get_root_of_modmap()
  local reporter
  local function _13_(log_path)
    if macro_recorded_3f(log_path) then
      local module_name = peek_module_name(log_path)
      local fnl_path = peek_fnl_path(log_path)
      local msg = ("%s\n- source file:\n  %s\n- dependency-map file:\n  %s"):format(module_name, fnl_path, log_path)
      return report_info(msg)
    else
      return nil
    end
  end
  reporter = _13_
  return each_file(reporter, root)
end
local function _15_()
  report_integrations()
  report_thyme_disk_info()
  report_fennel_paths()
  report_imported_macros()
  return report_thyme_config()
end
return {check = _15_}
