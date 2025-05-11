local ModuleMap = require("thyme.dependency.unit")
local _local_1_ = require("thyme.utils.uri")
local uri_encode = _local_1_["uri-encode"]
local _local_2_ = require("thyme.dependency.stackframe")
local validate_stackframe_21 = _local_2_["validate-stackframe!"]
local ModuleMapLogger = {}
ModuleMapLogger.__index = ModuleMapLogger
local module_maps = {}
ModuleMapLogger["log-module-map!"] = function(self, dependency_stackframe, dependent_callstack)
  validate_stackframe_21(dependency_stackframe)
  local dependency_fnl_path = dependency_stackframe["get-fnl-path"](dependency_stackframe)
  local _3_
  local or_4_ = module_maps[dependency_fnl_path]
  if not or_4_ then
    local modmap = ModuleMap.new(dependency_fnl_path)
    if not modmap["logged?"](modmap) then
      modmap["initialize-module-map!"](modmap, dependency_stackframe)
    else
    end
    self["_module-name->fnl-path"][dependency_stackframe["module-name"]] = dependency_stackframe["fnl-path"]
    self["_fnl-path->module-map"][dependency_stackframe["fnl-path"]] = modmap
    or_4_ = modmap
  end
  _3_ = or_4_
  if (nil ~= _3_) then
    local module_map = _3_
    local _7_ = dependent_callstack[#dependent_callstack]
    if (nil ~= _7_) then
      local dependent_stackframe = _7_
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
  local fnl_path = vim.fn.resolve(raw_fnl_path)
  local or_11_ = self["_fnl-path->module-map"][fnl_path]
  if not or_11_ then
    local modmap = ModuleMap.new(fnl_path)
    if modmap["logged?"](modmap) then
      module_maps[fnl_path] = modmap
    else
    end
    or_11_ = modmap
  end
  return or_11_
end
ModuleMapLogger["module-name->fnl-path"] = function(self, module_name)
  return self["_module-name->fnl-path"][module_name]
end
ModuleMapLogger["fnl-path->module-name"] = function(self, raw_fnl_path)
  local tgt_14_ = self["fnl-path->module-map"](self, raw_fnl_path)
  return (tgt_14_)["get-module-name"](tgt_14_)
end
ModuleMapLogger["module-name->module-map"] = function(self, module_name)
  local _15_ = self["module-name->fnl-path"](self, module_name)
  if (nil ~= _15_) then
    local fnl_path = _15_
    return self["_fnl-path->module-map"][fnl_path]
  else
    return nil
  end
end
ModuleMapLogger["_fnl-path->entry-map"] = function(self, fnl_path)
  local tgt_17_ = self["fnl-path->module-map"](self, fnl_path)
  return (tgt_17_)["get-entry-map"](tgt_17_)
end
ModuleMapLogger["fnl-path->dependent-maps"] = function(self, fnl_path)
  local tgt_18_ = self["fnl-path->module-map"](self, fnl_path)
  return (tgt_18_)["get-dependent-maps"](tgt_18_)[fnl_path]
end
ModuleMapLogger["fnl-path->lua-path"] = function(self, fnl_path)
  local _19_ = self["_fnl-path->entry-map"](self, fnl_path)
  if (nil ~= _19_) then
    local modmap = _19_
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
