local _local_1_ = require("thyme.const")
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local example_config_path = _local_1_["example-config-path"]
local _local_2_ = require("thyme.util.fs")
local read_file = _local_2_["read-file"]
local write_fnl_file_21 = _local_2_["write-fnl-file!"]
local case_3_ = vim.fn.confirm(("Missing \"%s\" at %s. Generate and open it?"):format(config_filename, vim.fn.stdpath("config")), "&No\n&yes", 1, "Warning")
if (case_3_ == 2) then
  local recommended_config = read_file(example_config_path)
  write_fnl_file_21(config_path, recommended_config)
  vim.cmd(("tabedit " .. config_path))
  local function _4_()
    return (config_path == vim.api.nvim_buf_get_name(0))
  end
  vim.wait(1000, _4_)
  vim.cmd("redraw!")
  if (config_path == vim.api.nvim_buf_get_name(0)) then
    local case_5_ = vim.fn.confirm("Trust this file? Otherwise, it will ask your trust again on nvim restart", "&No\n&yes", 1, "Question")
    if (case_5_ == 2) then
      local buf_name = vim.api.nvim_buf_get_name(0)
      assert((config_path == buf_name), ("expected %s, got %s"):format(config_path, buf_name))
      return vim.cmd("trust")
    else
      local _ = case_5_
      vim.secure.trust({action = "remove", path = config_path})
      local case_6_ = vim.fn.confirm(("Aborted trusting %s. Exit?"):format(config_path), "&No\n&yes", 1, "WarningMsg")
      if (case_6_ == 2) then
        return os.exit(1)
      else
        return nil
      end
    end
  else
    return nil
  end
else
  local _ = case_3_
  local case_10_ = vim.fn.confirm("Aborted proceeding with nvim-thyme. Exit?", "&No\n&yes", 1, "WarningMsg")
  if (case_10_ == 2) then
    return os.exit(1)
  else
    return nil
  end
end
