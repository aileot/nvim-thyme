local _local_1_ = require("bit")
local tohex = _local_1_.tohex
local Path = require("thyme.util.path")
local function encode_with_percent(char)
  return ("%" .. tohex(string.byte(char), 2))
end
local function uri_encode(uri)
  local appname = (vim.env.NVIM_APPNAME or "nvim")
  local split_pattern = ("/" .. appname .. ".-/")
  local percent_patterns = "[^A-Za-z0-9%-_.!~*'()]"
  local case_2_, case_3_ = string.find(uri, split_pattern)
  if (true and (nil ~= case_3_)) then
    local _start = case_2_
    local _end = case_3_
    local prefix = uri:sub(1, (_end - 1))
    local suffix = uri:sub((_end + 1))
    local prefix_encoded = prefix:gsub(percent_patterns, encode_with_percent)
    local suffix_encoded = suffix:gsub(percent_patterns, encode_with_percent)
    return Path.join(prefix_encoded, suffix_encoded)
  else
    local _ = case_2_
    return uri:gsub(percent_patterns, encode_with_percent)
  end
end
local function hex__3echar(hex)
  return string.char(tonumber(hex, 16))
end
local function uri_decode(uri)
  local case_5_ = uri:gsub("%%([a-fA-F0-9][a-fA-F0-9])", hex__3echar)
  if (nil ~= case_5_) then
    local decoded = case_5_
    return decoded
  else
    return nil
  end
end
return {["uri-encode"] = uri_encode, ["uri-decode"] = uri_decode}
