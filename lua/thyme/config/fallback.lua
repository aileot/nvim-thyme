local _local_1_ = require("thyme.const")
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local example_config_path = _local_1_["example-config-path"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local function should_fallback_3f()
  return not file_readable_3f(config_path)
end
local function display_example_config_21()
  vim.cmd(("tabedit " .. example_config_path))
  return vim.cmd("redraw!")
end
local function prompt_fallback_config_21()
  display_example_config_21()
  local _3_ = vim.fn.confirm(("Missing \"%s\" at %s. Copy the sane example config?"):format(config_filename, vim.fn.stdpath("config")), "&No\n&yes", 1, "Warning")
  if (_3_ == 2) then
    local config_root_dir = vim.fs.dirname(config_path)
    vim.fn.mkdir(config_root_dir, "p")
    return vim.cmd(("saveas " .. config_path))
  else
    local _ = _3_
    local _4_ = vim.fn.confirm("Aborted proceeding with nvim-thyme. Exit?", "&No\n&yes", 1, "WarningMsg")
    if (_4_ == 2) then
      return os.exit(1)
    else
      return nil
    end
  end
end
return {["should-fallback?"] = should_fallback_3f, ["prompt-fallback-config!"] = prompt_fallback_config_21}
