local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_2_["clear-cache!"]
local CmdCache = {}
CmdCache.open = function()
  return vim.cmd(("tab drop " .. lua_cache_prefix))
end
CmdCache.clear = function()
  return clear_cache_21()
end
CmdCache["setup!"] = function()
  vim.api.nvim_create_user_command("ThymeCacheOpen", CmdCache.open(), {desc = "[thyme] open the cache root directory"})
  local function _3_()
    if CmdCache.clear() then
      return vim.notify(("Cleared cache: " .. lua_cache_prefix))
    else
      return vim.notify(("No cache files detected at " .. lua_cache_prefix))
    end
  end
  return vim.api.nvim_create_user_command("ThymeCacheClear", _3_, {bar = true, bang = true, desc = "[thyme] clear the lua cache and dependency map logs"})
end
return CmdCache
