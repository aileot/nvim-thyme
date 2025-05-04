local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_2_["clear-cache!"]
local M = {}
M["setup!"] = function()
  local function _3_()
    return vim.cmd(("tab drop " .. lua_cache_prefix))
  end
  vim.api.nvim_create_user_command("ThymeCacheOpen", _3_, {desc = "[thyme] open the cache root directory"})
  local function _4_()
    if clear_cache_21() then
      return vim.notify(("Cleared cache: " .. lua_cache_prefix))
    else
      return vim.notify(("No cache files detected at " .. lua_cache_prefix))
    end
  end
  return vim.api.nvim_create_user_command("ThymeCacheClear", _4_, {bar = true, bang = true, desc = "[thyme] clear the lua cache and dependency map logs"})
end
return M
