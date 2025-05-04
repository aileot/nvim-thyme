local _local_1_ = require("thyme.const")
local config_path = _local_1_["config-path"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_2_["clear-cache!"]
local _local_3_ = require("thyme.user.check")
local check_to_update_21 = _local_3_["check-to-update!"]
local _local_4_ = require("thyme.config")
local get_config = _local_4_["get-config"]
local _3fgroup = nil
local function watch_files_21(_3fopts)
  local group
  local or_5_ = _3fgroup
  if not or_5_ then
    or_5_ = vim.api.nvim_create_augroup("ThymeWatch", {})
  end
  group = or_5_
  local config = get_config()
  local opts
  if _3fopts then
    opts = vim.tbl_deep_extend("force", config.watch, _3fopts)
  else
    opts = config.watch
  end
  local event = opts.event
  local pattern = opts.pattern
  local callback
  local function _8_(_7_)
    local fnl_path = _7_["match"]
    local resolved_path = vim.fn.resolve(fnl_path)
    if (config_path == resolved_path) then
      if clear_cache_21() then
        vim.notify(("Cleared cache: " .. lua_cache_prefix))
      else
      end
    else
      local _10_, _11_ = pcall(check_to_update_21, resolved_path, opts)
      if ((_10_ == false) and (nil ~= _11_)) then
        local msg = _11_
        vim.notify_once(msg, vim.log.levels.ERROR)
      else
      end
    end
    return nil
  end
  callback = _8_
  _3fgroup = group
  return vim.api.nvim_create_autocmd(event, {group = group, pattern = pattern, callback = callback})
end
return {["watch-files!"] = watch_files_21}
