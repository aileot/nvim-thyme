local fennel = require("fennel")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local config_path = _local_1_["config-path"]
local thyme_repo_root = _local_1_["thyme-repo-root"]
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
local ModuleMap = _local_7_
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
  do
    local git_cmd_2fget_version = ("git -C %q describe --tags || git -C %q status"):format(thyme_repo_root, thyme_repo_root)
    report.info(("The version of nvim-thyme: %s"):format(vim.fn.system(git_cmd_2fget_version)))
  end
  report.info(("The installation path of nvim-thyme: `%s`"):format(thyme_repo_root))
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
local function report_imported_macros()
  report.start("Thyme Imported Macros")
  local root = get_root_of_modmap()
  local reporter
  local function _12_(log_path)
    local modmap = ModuleMap["read-from-log-file"](log_path)
    if modmap["macro?"](modmap) then
      local module_name = modmap["get-module-name"](modmap)
      local fnl_path = modmap["get-fnl-path"](modmap)
      local dependent_list = modmap["pp-dependent-list"](modmap)
      local msg = ("%s\n- source file:\n  `%s`\n- dependent modules:\n%s"):format(module_name, fnl_path, dependent_list)
      return report.info(msg)
    else
      return nil
    end
  end
  reporter = _12_
  return each_file(reporter, root)
end
local function report_mounted_paths()
  report.start("Thyme Mounted Paths")
  local mounted_paths = RollbackManager["list-mounted-paths"]()
  if next(mounted_paths) then
    local resolved_paths
    do
      local tbl_21_ = {}
      local i_22_ = 0
      for _, path in ipairs(mounted_paths) do
        local val_23_ = vim.uv.fs_realpath(path)
        if (nil ~= val_23_) then
          i_22_ = (i_22_ + 1)
          tbl_21_[i_22_] = val_23_
        else
        end
      end
      resolved_paths = tbl_21_
    end
    return report.info(("The mounted paths:\n- `%s`"):format(table.concat(resolved_paths, "`\n- `")))
  else
    return report.info("No paths are mounted.")
  end
end
local function _16_()
  report_integrations()
  report_thyme_disk_info()
  report_fennel_paths()
  report_thyme_config()
  report_mounted_paths()
  return report_imported_macros()
end
return {check = _16_}
