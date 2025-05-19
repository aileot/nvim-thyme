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
  local _5_
  local or_6_ = module_maps[dependency_fnl_path]
  if not or_6_ then
    local logged_3f = ModuleMap["has-log?"](dependency_fnl_path)
    local modmap = ModuleMap.new(dependency_fnl_path)
    if not logged_3f then
      modmap["initialize-module-map!"](modmap, dependency_stackframe)
    else
    end
    self["_module-name->fnl-path"][dependency_stackframe["module-name"]] = dependency_stackframe["fnl-path"]
    self["_fnl-path->module-map"][dependency_stackframe["fnl-path"]] = modmap
    or_6_ = modmap
  end
  _5_ = or_6_
  if (nil ~= _5_) then
    local module_map = _5_
    local _9_ = dependent_callstack[#dependent_callstack]
    if (nil ~= _9_) then
      local dependent_stackframe = _9_
      if not module_map["get-dependent-maps"](module_map)[dependency_fnl_path] then
        return module_map["log-dependent!"](module_map, dependent_stackframe)
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
ModuleMapLogger["fnl-path->module-map"] = function(self, raw_fnl_path)
  assert_is_file_readable(raw_fnl_path)
  local fnl_path = vim.fn.resolve(raw_fnl_path)
  local or_13_ = self["_fnl-path->module-map"][fnl_path]
  if not or_13_ then
    local modmap = ModuleMap.new(fnl_path)
    if ModuleMap["has-log?"](fnl_path) then
      module_maps[fnl_path] = modmap
    else
    end
    or_13_ = modmap
  end
  return or_13_
end
ModuleMapLogger["module-name->fnl-path"] = function(self, module_name)
  validate_type("string", module_name)
  return self["_module-name->fnl-path"]:get(module_name)
end
ModuleMapLogger["fnl-path->module-name"] = function(self, raw_fnl_path)
  local tgt_16_ = self["fnl-path->module-map"](self, raw_fnl_path)
  return (tgt_16_)["get-module-name"](tgt_16_)
end
ModuleMapLogger["module-name->module-map"] = function(self, module_name)
  local _17_ = self["module-name->fnl-path"](self, module_name)
  if (nil ~= _17_) then
    local fnl_path = _17_
    return self["_fnl-path->module-map"][fnl_path]
  else
    return nil
  end
end
ModuleMapLogger["_fnl-path->entry-map"] = function(self, fnl_path)
  local tgt_19_ = self["fnl-path->module-map"](self, fnl_path)
  return (tgt_19_)["get-entry-map"](tgt_19_)
end
ModuleMapLogger["fnl-path->dependent-maps"] = function(self, fnl_path)
  local tgt_20_ = self["fnl-path->module-map"](self, fnl_path)
  return (tgt_20_)["get-dependent-maps"](tgt_20_)
end
ModuleMapLogger["fnl-path->lua-path"] = function(self, fnl_path)
  local _21_ = self["_fnl-path->entry-map"](self, fnl_path)
  if (nil ~= _21_) then
    local modmap = _21_
    return modmap["lua-path"]
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
  self["_module-name->fnl-path"] = {}
  self["_fnl-path->module-map"] = {}
  return self
end
local SingletonModuleMapLogger = ModuleMapLogger._new()
return SingletonModuleMapLogger
