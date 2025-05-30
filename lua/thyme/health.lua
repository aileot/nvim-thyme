local fennel = require("fennel")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.config")
local get_config = _local_2_["get-config"]
local _local_3_ = require("thyme.util.iterator")
local each_file = _local_3_["each-file"]
local _local_4_ = require("thyme.rollback.manager")
local get_root_of_backup = _local_4_["get-root"]
local _local_5_ = require("thyme.util.pool")
local get_root_of_pool = _local_5_["get-root"]
local _local_6_ = require("thyme.wrapper.nvim")
local get_runtime_files = _local_6_["get-runtime-files"]
local _local_7_ = require("thyme.dependency.unit")
local get_root_of_modmap = _local_7_["get-root"]
local RollbackManager = require("thyme.rollback.manager")
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
    reporter(("`%s`"):format(("vim.g.parinfer_loaded = " .. tostring(vim.g.parinfer_loaded))))
  end
  local dependency_files = {"parser/fennel.so"}
  for _, file in ipairs(dependency_files) do
    local _10_ = get_runtime_files({file}, false)
    if ((_G.type(_10_) == "table") and (nil ~= _10_[1])) then
      local path = _10_[1]
      report_ok(("`%s` is detected at `%s`."):format(file, path))
    else
      local _0 = _10_
      report_warn(("missing `%s`."):format(file))
    end
  end
  return nil
end
local function report_thyme_disk_info()
  report_start("Thyme Disk Info")
  report_info(("The path to .nvim-thyme.fnl: `%s`"):format(config_path))
  report_info(("The root path of Lua cache:  `%s`"):format(lua_cache_prefix))
  report_info(("The root path of backups for rollback: `%s`"):format(get_root_of_backup()))
  report_info(("The root path of module-mapping: `%s`"):format(get_root_of_modmap()))
  return report_info(("The root path of pool: `%s`"):format(get_root_of_pool()))
end
local function report_thyme_config()
  report_start("Thyme .nvim-thyme.fnl")
  local config = get_config()
  return report_info(("The current config:\n\n%s\n"):format(fennel.view(config)))
end
local function report_fennel_paths()
  report_start("Thyme fennel.{path,macro-path}")
  report_info(("fennel.path:\n- `%s`"):format(fennel.path:gsub(";", "`\n- `")))
  return report_info(("fennel.macro-path:\n- `%s`"):format(fennel["macro-path"]:gsub(";", "`\n- `")))
end
local function _12_()
  report_integrations()
  report_thyme_disk_info()
  report_fennel_paths()
  return report_thyme_config()
end
return {check = _12_}
