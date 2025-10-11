local _local_1_ = require("thyme.const")
local config_path = _local_1_["config-path"]
local Path = require("thyme.util.path")
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local M = {}
M["recorded?"] = function(raw_path)
  local resolved_path = raw_path
  local trust_database_path = Path.join(vim.fn.stdpath("state"), "trust")
  if file_readable_3f(trust_database_path) then
    local trust_contents = vim.fn.readfile(trust_database_path)
    local trusted_3f = false
    for _, line in ipairs(trust_contents) do
      if trusted_3f then break end
      if (line:find((" " .. config_path), 1, true) or line:find((" " .. resolved_path))) then
        trusted_3f = true
      else
        trusted_3f = false
      end
    end
    return trusted_3f
  else
    return false
  end
end
M["allowed?"] = function(raw_path)
  local resolved_path = raw_path
  local trust_database_path = Path.join(vim.fn.stdpath("state"), "trust")
  if file_readable_3f(trust_database_path) then
    local trust_contents = vim.fn.readfile(trust_database_path)
    local allowed_pattern = ("^%s+ "):format(string.rep("%x", 8))
    local trusted_3f = false
    for _, line in ipairs(trust_contents) do
      if trusted_3f then break end
      local case_5_ = (line:find((" " .. config_path), 1, true) or line:find((" " .. resolved_path)))
      if (case_5_ == nil) then
        trusted_3f = false
      else
        local _0 = case_5_
        if line:find(allowed_pattern) then
          trusted_3f = true
        else
          trusted_3f = false
        end
      end
    end
    return trusted_3f
  else
    return false
  end
end
M["denied?"] = function(raw_path)
  local resolved_path = raw_path
  local trust_database_path = Path.join(vim.fn.stdpath("state"), "trust")
  if file_readable_3f(trust_database_path) then
    local trust_contents = vim.fn.readfile(trust_database_path)
    local denied_pattern = "^! "
    local trusted_3f = false
    for _, line in ipairs(trust_contents) do
      if trusted_3f then break end
      local case_9_ = (line:find((" " .. config_path), 1, true) or line:find((" " .. resolved_path)))
      if (case_9_ == nil) then
        trusted_3f = false
      else
        local _0 = case_9_
        if line:find(denied_pattern) then
          trusted_3f = true
        else
          trusted_3f = false
        end
      end
    end
    return trusted_3f
  else
    return false
  end
end
return M
