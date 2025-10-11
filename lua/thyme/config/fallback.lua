local _local_1_ = require("thyme.const")
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local example_config_path = _local_1_["example-config-path"]
local function display_example_config_21()
  vim.cmd(("tabedit " .. example_config_path))
  return vim.cmd("redraw!")
end
local function prompt_fallback_config_21()
  display_example_config_21()
  local case_2_ = vim.fn.confirm(("Missing \"%s\" at %s. Copy the sane example config?"):format(config_filename, vim.fn.stdpath("config")), "&No\n&yes", 1, "Warning")
  if (case_2_ == 2) then
    vim.cmd(("saveas " .. config_path))
    local case_3_ = vim.fn.confirm("Trust this file? Otherwise, it will ask your trust again on nvim restart", "&No\n&yes", 1, "Question")
    if (case_3_ == 2) then
      local buf_name = vim.api.nvim_buf_get_name(0)
      assert((buf_name == example_config_path), ("expected %s, got %s"):format(example_config_path, buf_name))
      return vim.cmd("trust")
    else
      local _ = case_3_
      vim.secure.trust({action = "remove", path = config_path})
      local case_4_ = vim.fn.confirm(("Aborted trusting %s. Exit?"):format(config_path), "&No\n&yes", 1, "WarningMsg")
      if (case_4_ == 2) then
        return os.exit(1)
      else
        return nil
      end
    end
  else
    local _ = case_2_
    local case_7_ = vim.fn.confirm("Aborted proceeding with nvim-thyme. Exit?", "&No\n&yes", 1, "WarningMsg")
    if (case_7_ == 2) then
      return os.exit(1)
    else
      return nil
    end
  end
end
return {["prompt-fallback-config!"] = prompt_fallback_config_21}
