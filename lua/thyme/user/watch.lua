local _local_1_ = require("thyme.const")
local config_path = _local_1_["config-path"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_2_["clear-cache!"]
local _local_3_ = require("thyme.user.check")
local check_to_update_21 = _local_3_["check-to-update!"]
local Config = require("thyme.config")
local _3fgroup = nil
local function watch_files_21(_3fopts)
  local group
  local or_4_ = _3fgroup
  if not or_4_ then
    or_4_ = vim.api.nvim_create_augroup("ThymeWatch", {})
  end
  group = or_4_
  local opts
  if _3fopts then
    opts = vim.tbl_deep_extend("force", Config.watch, _3fopts)
  else
    opts = Config.watch
  end
  local callback
  local function _7_(_6_)
    local fnl_path = _6_["match"]
    local resolved_path = vim.fn.resolve(fnl_path)
    if (config_path == resolved_path) then
      if clear_cache_21() then
        vim.notify(("Cleared cache: " .. lua_cache_prefix))
      else
      end
    else
      local _9_, _10_ = pcall(check_to_update_21, resolved_path, opts)
      if ((_9_ == false) and (nil ~= _10_)) then
        local msg = _10_
        vim.notify_once(msg, vim.log.levels.ERROR)
      else
      end
    end
    return nil
  end
  callback = _7_
  _3fgroup = group
  return vim.api.nvim_create_autocmd(opts.event, {group = group, pattern = opts.pattern, callback = callback})
end
return {["watch-files!"] = watch_files_21}
