local _local_1_ = require("bit")
local tohex = _local_1_["tohex"]
local Path = require("thyme.utils.path")
local appname = (vim.env.NVIM_APPNAME or "nvim")
local split_pattern = ("/" .. appname .. "/")
local function encode_with_percent(char)
  return ("%" .. tohex(string.byte(char), 2))
end
local function uri_encode(uri)
  local percent_patterns = "[^A-Za-z0-9%-_.!~*'()]"
  local _start, _end = string.find(uri, split_pattern, 1, true)
  local prefix = uri:sub(1, (_end - 1))
  local suffix = uri:sub((_end + 1))
  local prefix_encoded = prefix:gsub(percent_patterns, encode_with_percent)
  local suffix_encoded = suffix:gsub(percent_patterns, encode_with_percent)
  return Path.join(prefix_encoded, suffix_encoded)
end
local function hex__3echar(hex)
  return string.char(tonumber(hex, 16))
end
local function uri_decode(uri)
  local _2_ = uri:gsub("%%([a-fA-F0-9][a-fA-F0-9])", hex__3echar)
  if (nil ~= _2_) then
    local decoded = _2_
    return decoded
  else
    return nil
  end
end
return {["uri-encode"] = uri_encode, ["uri-decode"] = uri_decode}
