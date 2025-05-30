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
local report
if vim.health.start then
  report = vim.health
else
  report = {start = vim.health.report_start, info = vim.health.report_info, ok = vim.health.report_ok, warn = vim.health.report_warn, error = vim.health.report_error}
end
local function report_integrations()
  report.start("Thyme Integrations")
  do
    local reporter
    if (nil == vim.g.parinfer_loaded) then
      reporter = report.warn
    else
      reporter = report.ok
    end
    reporter(("`%s`"):format(("vim.g.parinfer_loaded = " .. tostring(vim.g.parinfer_loaded))))
  end
  local dependency_files = {"parser/fennel.so"}
  for _, file in ipairs(dependency_files) do
    local _10_ = get_runtime_files({file}, false)
    if ((_G.type(_10_) == "table") and (nil ~= _10_[1])) then
      local path = _10_[1]
      report.ok(("`%s` is detected at `%s`."):format(file, path))
    else
      local _0 = _10_
      report.warn(("missing `%s`."):format(file))
    end
  end
  return nil
end
local function report_thyme_disk_info()
  report.start("Thyme Disk Info")
  report.info(("The path to .nvim-thyme.fnl: `%s`"):format(config_path))
  report.info(("The root path of Lua cache:  `%s`"):format(lua_cache_prefix))
  report.info(("The root path of backups for rollback: `%s`"):format(get_root_of_backup()))
  report.info(("The root path of module-mapping: `%s`"):format(get_root_of_modmap()))
  return report.info(("The root path of pool: `%s`"):format(get_root_of_pool()))
end
local function report_thyme_config()
  report.start("Thyme .nvim-thyme.fnl")
  local config = get_config()
  return report.info(("The current config:\n\n%s\n"):format(fennel.view(config)))
end
local function report_fennel_paths()
  report.start("Thyme fennel.{path,macro-path}")
  report.info(("fennel.path:\n- `%s`"):format(fennel.path:gsub(";", "`\n- `")))
  return report.info(("fennel.macro-path:\n- `%s`"):format(fennel["macro-path"]:gsub(";", "`\n- `")))
end
local function _12_()
  report_integrations()
  report_thyme_disk_info()
  report_fennel_paths()
  return report_thyme_config()
end
return {check = _12_}
