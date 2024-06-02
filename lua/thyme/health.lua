local fennel = require("fennel")
local function report_fennel_paths()
  vim.health.start("Thyme fennel.{path,macro-path}")
  vim.health.info(("fennel.path:\n- " .. (fennel.path):gsub(";", "\n- ")))
  return vim.health.info(("fennel.macro-path:\n- " .. (fennel["macro-path"]):gsub(";", "\n- ")))
end
local function _1_()
  return report_fennel_paths()
end
return {check = _1_}
