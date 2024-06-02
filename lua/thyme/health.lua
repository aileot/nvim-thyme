local fennel = require("fennel")
local _local_1_ = require("thyme.config")
local get_main_config = _local_1_["get-main-config"]
local report_start, report_info, report_ok, report_warn, report_error = nil, nil, nil, nil, nil
do
  local health = vim.health
  if health.start then
    report_start, report_info, report_ok, report_warn, report_error = health.start, health.info, health.ok, health.warn, health.error
  else
    report_start, report_info, report_ok, report_warn, report_error = health.report_start, health.report_info, health.report_ok, health.report_warn, health.report_error
  end
end
local function report_thyme_config()
  report_start("Thyme .nvim-thyme.fnl")
  return report_info(("The current config:\n" .. fennel.view(get_main_config())))
end
local function report_fennel_paths()
  report_start("Thyme fennel.{path,macro-path}")
  report_info(("fennel.path:\n- " .. (fennel.path):gsub(";", "\n- ")))
  return report_info(("fennel.macro-path:\n- " .. (fennel["macro-path"]):gsub(";", "\n- ")))
end
local function _3_()
  report_thyme_config()
  return report_fennel_paths()
end
return {check = _3_}
