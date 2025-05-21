local ModuleMap = require("thyme.dependency.unit")
local _local_1_ = require("thyme.utils.general")
local validate_type = _local_1_["validate-type"]
local _local_2_ = require("thyme.utils.uri")
local uri_encode = _local_2_["uri-encode"]
local _local_3_ = require("thyme.utils.fs")
local assert_is_file_readable = _local_3_["assert-is-file-readable"]
local HashMap = require("thyme.utils.hashmap")
local _local_4_ = require("thyme.dependency.stackframe")
local validate_stackframe_21 = _local_4_["validate-stackframe!"]
local ModuleMapLogger = {}
ModuleMapLogger.__index = ModuleMapLogger
local module_maps = {}
ModuleMapLogger["log-module-map!"] = function(self, dependency_stackframe, dependent_callstack)
  validate_stackframe_21(dependency_stackframe)
  local dependency_fnl_path = dependency_stackframe["get-fnl-path"](dependency_stackframe)
  local module_map
  if ModuleMap["has-log?"](dependency_fnl_path) then
    local map = ModuleMap["try-read-from-file"](dependency_fnl_path)
    if (map["macro?"](map) and dependency_stackframe["get-lua-path"](dependency_stackframe)) then
      map = ModuleMap.new(dependency_stackframe)
      map["write-file!"](map)
    else
    end
    module_map = map
  else
    local map = ModuleMap.new(dependency_stackframe)
    module_map = map["write-file!"](map)
  end
  self["_module-name->fnl-path"]["insert!"](self["_module-name->fnl-path"], dependency_stackframe["module-name"], dependency_stackframe["fnl-path"])
  self["_fnl-path->module-map"]["insert!"](self["_fnl-path->module-map"], dependency_stackframe["fnl-path"], module_map)
  local _7_ = dependent_callstack[#dependent_callstack]
  if (nil ~= _7_) then
    local dependent_stackframe = _7_
    return module_map["log-dependent!"](module_map, dependent_stackframe)
  else
    return nil
  end
end
ModuleMapLogger["fnl-path->module-map"] = function(self, raw_fnl_path)
  local or_9_ = self["_fnl-path->module-map"]:get(raw_fnl_path)
  if not or_9_ then
    if ModuleMap["has-log?"](raw_fnl_path) then
      local modmap = ModuleMap["try-read-from-file"](raw_fnl_path)
      self["_fnl-path->module-map"]["insert!"](self["_fnl-path->module-map"], raw_fnl_path, modmap)
      or_9_ = modmap
    else
      or_9_ = nil
    end
  end
  return or_9_
end
ModuleMapLogger["module-name->fnl-path"] = function(self, module_name)
  validate_type("string", module_name)
  return self["_module-name->fnl-path"]:get(module_name)
end
ModuleMapLogger["fnl-path->module-name"] = function(self, raw_fnl_path)
  local tmp_3_ = self["fnl-path->module-map"](self, raw_fnl_path)
  if (nil ~= tmp_3_) then
    return tmp_3_["get-module-name"](tmp_3_)
  else
    return nil
  end
end
ModuleMapLogger["module-name->module-map"] = function(self, module_name)
  local _13_ = self["module-name->fnl-path"](self, module_name)
  if (nil ~= _13_) then
    local fnl_path = _13_
    return self["_fnl-path->module-map"]:get(fnl_path)
  else
    return nil
  end
end
ModuleMapLogger["fnl-path->dependent-maps"] = function(self, fnl_path)
  local tgt_15_ = self["fnl-path->module-map"](self, fnl_path)
  return (tgt_15_)["get-dependent-maps"](tgt_15_)
end
ModuleMapLogger["fnl-path->lua-path"] = function(self, fnl_path)
  local tmp_3_ = self["fnl-path->module-map"](self, fnl_path)
  if (nil ~= tmp_3_) then
    return tmp_3_["get-lua-path"](tmp_3_)
  else
    return nil
  end
end
ModuleMapLogger["clear-module-map!"] = function(self, fnl_path)
  local modmap = self["fnl-path->module-map"](self, fnl_path)
  module_maps[uri_encode(fnl_path)] = modmap
  module_maps[fnl_path] = nil
  return nil
end
ModuleMapLogger["restore-module-map!"] = function(self, fnl_path)
  local modmap = self["fnl-path->module-map"](self, uri_encode(fnl_path))
  module_maps[fnl_path] = modmap
  return nil
end
ModuleMapLogger._new = function()
  local self = setmetatable({}, ModuleMapLogger)
  self["_module-name->fnl-path"] = HashMap.new()
  self["_fnl-path->module-map"] = HashMap.new()
  return self
end
local SingletonModuleMapLogger = ModuleMapLogger._new()
return SingletonModuleMapLogger
