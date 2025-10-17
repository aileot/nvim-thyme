local Path = require("thyme.util.path")
local config_filename = ".nvim-thyme.fnl"
local stdpath_config = vim.fn.stdpath("config")
local rtp = vim.api.nvim_get_option_value("rtp", {})
local config_path = vim.fn.resolve(Path.join(stdpath_config, config_filename))
local cache_prefix = assert((rtp:match("([^,]+/thyme/compile[^,]-),") or rtp:match("([^,]+/thyme/compile[^,]-)$")), ("&runtimepath must contains a unique path which literally includes `/thyme/compile`; got " .. vim.inspect(vim.opt.rtp:get())))
local lua_cache_prefix = vim.fn.expand(Path.join(cache_prefix, "lua"))
local example_config_path
do
  local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
  local example_config_filename = (config_filename .. ".example")
  local _let_1_ = vim.fs.find(example_config_filename, {upward = true, type = "file", path = this_dir})
  local example_config_path0 = _let_1_[1]
  example_config_path = example_config_path0
end
local thyme_repo_root = vim.fs.dirname(example_config_path)
return {["debug?"] = ("1" == vim.env.THYME_DEBUG), ["stdpath-config"] = stdpath_config, ["lua-cache-prefix"] = lua_cache_prefix, ["config-filename"] = config_filename, ["config-path"] = config_path, ["example-config-path"] = example_config_path, ["thyme-repo-root"] = thyme_repo_root, ["state-prefix"] = Path.join(vim.fn.stdpath("state"), "thyme")}
