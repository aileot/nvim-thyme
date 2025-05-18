local fennel = require("fennel")
local _local_1_ = require("thyme.const")
local config_path = _local_1_["config-path"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.utils.trust")
local allowed_3f = _local_2_["allowed?"]
local Messenger = require("thyme.utils.messenger")
local WatchMessenger = Messenger.new("watch")
local _local_3_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_3_["clear-cache!"]
local _local_4_ = require("thyme.user.check")
local check_to_update_21 = _local_4_["check-to-update!"]
local Config = require("thyme.config")
local _3fgroup = nil
local function watch_files_21(_3fopts)
  local group
  local or_5_ = _3fgroup
  if not or_5_ then
    or_5_ = vim.api.nvim_create_augroup("ThymeWatch", {})
  end
  group = or_5_
  local opts
  if _3fopts then
    opts = vim.tbl_deep_extend("force", Config.watch, _3fopts)
  else
    opts = Config.watch
  end
  local callback
  local function _8_(_7_)
    local fnl_path = _7_["match"]
    local resolved_path = vim.fn.resolve(fnl_path)
    if (config_path == resolved_path) then
      if allowed_3f(config_path) then
        vim.cmd("silent trust")
      else
      end
      if clear_cache_21() then
        local msg = ("Cleared all the cache under " .. lua_cache_prefix)
        WatchMessenger["notify!"](WatchMessenger, msg)
      else
      end
    else
      local _11_, _12_ = nil, nil
      local function _13_()
        return check_to_update_21(resolved_path, opts)
      end
      _11_, _12_ = xpcall(_13_, fennel.traceback)
      if ((_11_ == false) and (nil ~= _12_)) then
        local msg = _12_
        WatchMessenger["notify!"](WatchMessenger, msg, vim.log.levels.ERROR)
      else
      end
    end
    return nil
  end
  callback = _8_
  _3fgroup = group
  return vim.api.nvim_create_autocmd(opts.event, {group = group, pattern = opts.pattern, callback = callback})
end
return {["watch-files!"] = watch_files_21}
