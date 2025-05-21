local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local Messenger = require("thyme.utils.class.messenger")
local CommandMessenger = Messenger.new("command/cache")
local _local_2_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_2_["clear-cache!"]
local CmdCache = {}
CmdCache.open = function()
  return vim.api.nvim_exec2(("tab drop " .. lua_cache_prefix), {})
end
CmdCache.clear = function()
  return clear_cache_21()
end
CmdCache["setup!"] = function()
  vim.api.nvim_create_user_command("ThymeCacheOpen", CmdCache.open, {desc = "[thyme] open the cache root directory"})
  local function _3_()
    local cleared_any_3f = CmdCache.clear()
    local msg
    if cleared_any_3f then
      msg = ("clear all the cache under " .. lua_cache_prefix)
    else
      msg = ("no cache files detected at " .. lua_cache_prefix)
    end
    return CommandMessenger["notify!"](CommandMessenger, msg)
  end
  return vim.api.nvim_create_user_command("ThymeCacheClear", _3_, {desc = "[thyme] clear the lua cache and dependency map logs"})
end
return CmdCache
