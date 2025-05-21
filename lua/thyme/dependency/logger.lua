local ModuleMap = require("thyme.dependency.unit")
local _local_1_ = require("thyme.util.general")
local validate_type = _local_1_["validate-type"]
local _local_2_ = require("thyme.util.uri")
local uri_encode = _local_2_["uri-encode"]
local HashMap = require("thyme.util.class.hashmap")
local _local_3_ = require("thyme.dependency.stackframe")
local validate_stackframe_21 = _local_3_["validate-stackframe!"]
local ModuleMapLogger = {}
ModuleMapLogger.__index = ModuleMapLogger
local module_maps = {}
ModuleMapLogger["log-module-map!"] = function(self, dependency_stackframe, dependent_callstack)
  validate_stackframe_21(dependency_stackframe)
  local dependency_fnl_path = dependency_stackframe["get-fnl-path"](dependency_stackframe)
  local module_map
  do
    local _4_ = ModuleMap["try-read-from-file"](dependency_fnl_path)
    if (_4_ == nil) then
      local tgt_5_ = ModuleMap.new(dependency_stackframe)
      module_map = (tgt_5_)["write-file!"](tgt_5_)
    elseif (nil ~= _4_) then
      local map = _4_
      if (map["macro?"](map) and dependency_stackframe["get-lua-path"](dependency_stackframe)) then
        local tgt_6_ = ModuleMap.new(dependency_stackframe)
        module_map = (tgt_6_)["write-file!"](tgt_6_)
      else
        module_map = map
      end
    else
      module_map = nil
    end
  end
  self["_module-name->fnl-path"]["insert!"](self["_module-name->fnl-path"], dependency_stackframe["module-name"], dependency_stackframe["fnl-path"])
  self["_fnl-path->module-map"]["insert!"](self["_fnl-path->module-map"], dependency_stackframe["fnl-path"], module_map)
  local _9_ = dependent_callstack[#dependent_callstack]
  if (nil ~= _9_) then
    local dependent_stackframe = _9_
    return module_map["log-dependent!"](module_map, dependent_stackframe)
  else
    return nil
  end
end
ModuleMapLogger["fnl-path->module-map"] = function(self, raw_fnl_path)
  local or_11_ = self["_fnl-path->module-map"]:get(raw_fnl_path)
  if not or_11_ then
    local _12_ = ModuleMap["try-read-from-file"](raw_fnl_path)
    if (nil ~= _12_) then
      local modmap = _12_
      self["_fnl-path->module-map"]["insert!"](self["_fnl-path->module-map"], raw_fnl_path, modmap)
      or_11_ = modmap
    else
      or_11_ = nil
    end
  end
  return or_11_
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
  local _17_ = self["module-name->fnl-path"](self, module_name)
  if (nil ~= _17_) then
    local fnl_path = _17_
    return self["_fnl-path->module-map"]:get(fnl_path)
  else
    return nil
  end
end
ModuleMapLogger["fnl-path->dependent-maps"] = function(self, fnl_path)
  local tgt_19_ = self["fnl-path->module-map"](self, fnl_path)
  return (tgt_19_)["get-dependent-maps"](tgt_19_)
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
