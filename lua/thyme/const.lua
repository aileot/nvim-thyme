local Path = require("thyme.util.path")
local config_filename = ".nvim-thyme.fnl"
local stdpath_config = vim.fn.stdpath("config")
local rtp = vim.api.nvim_get_option_value("rtp", {})
local config_path = vim.fn.resolve(Path.join(stdpath_config, config_filename))
local cache_prefix = assert((rtp:match("([^,]+/thyme/compile[^,]-),") or rtp:match("([^,]+/thyme/compile[^,]-)$")), ("&runtimepath must contains a unique path which literally includes `/thyme/compile`; got " .. vim.inspect(vim.opt.rtp:get())))
local lua_cache_prefix = vim.fn.expand(Path.join(cache_prefix, "lua"))
return {["debug?"] = ("1" == vim.env.THYME_DEBUG), ["stdpath-config"] = stdpath_config, ["lua-cache-prefix"] = lua_cache_prefix, ["config-filename"] = config_filename, ["config-path"] = config_path, ["state-prefix"] = Path.join(vim.fn.stdpath("state"), "thyme")}
