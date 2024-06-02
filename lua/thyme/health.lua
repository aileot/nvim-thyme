local fennel = require("fennel")
local _local_1_ = require("thyme.config")
local get_main_config = _local_1_["get-main-config"]
local function report_thyme_config()
  vim.health.start("Thyme current config on .nvim-thyme.fnl")
  return vim.health.info(fennel.view(get_main_config()))
end
local function report_fennel_paths()
  vim.health.start("Thyme fennel.{path,macro-path}")
  vim.health.info(("fennel.path:\n- " .. (fennel.path):gsub(";", "\n- ")))
  return vim.health.info(("fennel.macro-path:\n- " .. (fennel["macro-path"]):gsub(";", "\n- ")))
end
local function _2_()
  report_thyme_config()
  return report_fennel_paths()
end
return {check = _2_}
