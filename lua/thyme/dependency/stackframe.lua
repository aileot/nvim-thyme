local _local_1_ = require("thyme.utils.fs")
local assert_is_file_readable = _local_1_["assert-is-file-readable"]
local Stackframe = {}
Stackframe.__index = Stackframe
Stackframe["get-module-name"] = function(self)
  return self["module-name"]
end
Stackframe["get-fnl-path"] = function(self)
  return self["fnl-path"]
end
Stackframe["get-lua-path"] = function(self)
  return self["lua-path"]
end
Stackframe.new = function(_2_)
  local module_name = _2_["module-name"]
  local fnl_path = _2_["fnl-path"]
  local _3flua_path = _2_["?lua-path"]
  local self = setmetatable({}, Stackframe)
  self["module-name"] = module_name
  assert_is_file_readable(fnl_path)
  self["fnl-path"] = vim.fn.resolve(fnl_path)
  self["lua-path"] = _3flua_path
  return self
end
Stackframe["validate-stackframe!"] = function(val)
  assert(("table" == type(val)), ("expected a table; got " .. type(val)))
  assert(next(val), "expected a non-empty table")
  assert_is_file_readable(val["fnl-path"])
  return assert(("string" == type(val["module-name"])), "`module-name` must be a string")
end
return Stackframe
