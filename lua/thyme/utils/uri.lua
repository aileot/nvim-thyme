


 local _local_1_ = require("bit") local tohex = _local_1_["tohex"]

 local function encode_with_percent(char)
 return ("%" .. tohex(string.byte(char), 2)) end



 local function uri_encode(uri) local percent_patterns = "[^A-Za-z0-9%-_.!~*'()]" return uri:gsub(percent_patterns, encode_with_percent) end



 local function hex__3echar(hex)
 return string.char(tonumber(hex, 16)) end


 local function uri_decode(uri) return uri:gsub("%%([a-fA-F0-9][a-fA-F0-9])", hex__3echar) end


 return {["uri-encode"] = uri_encode, ["uri-decode"] = uri_decode}
