

 local Path = require("thyme.utils.path") local config_filename = ".nvim-thyme.fnl"



 local stdpath_config = vim.fn.stdpath("config")

 local rtp = vim.api.nvim_get_option_value("rtp", {})



 local config_path = Path.join(stdpath_config, config_filename)


 local cache_prefix = assert((rtp:match("([^,]+/thyme/compile[^,]-),") or rtp:match("([^,]+/thyme/compile[^,]-)$")), "&runtimepath must contains a unique path which literally includes `/thyme/compile`.")






 local lua_cache_prefix = vim.fn.expand(Path.join(cache_prefix, "lua"))


 local fnl_src_prefix = Path.join(stdpath_config, "fnl")
 local resolved_src_prefix = vim.fn.resolve(fnl_src_prefix)
 local fnl_src_prefixes
 if (fnl_src_prefix == resolved_src_prefix) then
 fnl_src_prefixes = {fnl_src_prefix} else
 fnl_src_prefixes = {fnl_src_prefix, resolved_src_prefix} end

 return {["stdpath-config"] = stdpath_config, ["lua-cache-prefix"] = lua_cache_prefix, ["config-filename"] = config_filename, ["config-path"] = config_path, ["state-prefix"] = Path.join(vim.fn.stdpath("state"), "thyme"), ["fnl-src-prefix"] = Path.join(stdpath_config, "fnl")}
