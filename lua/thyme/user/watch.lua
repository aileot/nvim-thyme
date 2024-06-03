local _local_1_ = require("thyme.const")
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_2_["clear-cache!"]
local _local_3_ = require("thyme.user.check")
local check_to_update_21 = _local_3_["check-to-update!"]
local _3fgroup = nil
local function watch_to_update_21(_3fopts)
  local group
  local function _4_(...)
    return vim.api.nvim_create_augroup("ThymeWatch", {})
  end
  group = (_3fgroup or _4_())
  local opts = (_3fopts or {})
  local event = (opts.event or {"BufWritePost", "FileChangedShellPost"})
  local pattern = (opts.pattern or "*.fnl")
  local callback
  local function _6_(_5_)
    local fnl_path = _5_["match"]
    local resolved_path = vim.fn.resolve(fnl_path)
    if (config_path == resolved_path) then
      clear_cache_21()
    else
      check_to_update_21(resolved_path, opts)
    end
    return nil
  end
  callback = _6_
  _3fgroup = group
  return vim.api.nvim_create_autocmd(event, {group = group, pattern = pattern, callback = callback})
end
return {["watch-to-update!"] = watch_to_update_21}
