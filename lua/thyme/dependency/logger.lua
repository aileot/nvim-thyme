local ModuleMap = require("thyme.dependency.unit")
local _local_1_ = require("thyme.utils.uri")
local uri_encode = _local_1_["uri-encode"]
local module_maps = {}
local function fnl_path__3emodule_map(fnl_path)
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/dependency/logger.fnl:9")
  local or_2_ = rawget(module_maps, fnl_path)
  if not or_2_ then
    local modmap = ModuleMap.new(fnl_path)
    if modmap["logged?"](modmap) then
      module_maps[fnl_path] = modmap
    else
    end
    or_2_ = modmap
  end
  return or_2_
end
local function log_module_map_21(dependency_stackframe, dependent_callstack)
  local dependency_fnl_path = dependency_stackframe["get-fnl-path"](dependency_stackframe)
  local _5_
  local or_6_ = module_maps[dependency_fnl_path]
  if not or_6_ then
    local modmap = ModuleMap.new(dependency_fnl_path)
    if not modmap["logged?"](modmap) then
      modmap["initialize-module-map!"](modmap, dependency_stackframe)
    else
    end
    module_maps[dependency_fnl_path] = modmap
    or_6_ = modmap
  end
  _5_ = or_6_
  if (nil ~= _5_) then
    local module_map = _5_
    local _9_ = dependent_callstack[#dependent_callstack]
    if (nil ~= _9_) then
      local dependent = _9_
      if not module_map["get-dependent-maps"](module_map)[dependency_fnl_path] then
        return module_map["log-dependent!"](module_map, dependent)
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
local function fnl_path__3eentry_map(fnl_path)
  local tgt_13_ = fnl_path__3emodule_map(fnl_path)
  return (tgt_13_)["get-entry-map"](tgt_13_)
end
local function fnl_path__3edependent_map(fnl_path)
  local tgt_14_ = fnl_path__3emodule_map(fnl_path)
  return (tgt_14_)["get-dependent-maps"](tgt_14_)[fnl_path]
end
local function fnl_path__3elua_path(fnl_path)
  local _15_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _15_) then
    local modmap = _15_
    return modmap["lua-path"]
  else
    return nil
  end
end
local function clear_module_map_21(fnl_path)
  local modmap = fnl_path__3emodule_map(fnl_path)
  module_maps[uri_encode(fnl_path)] = modmap
  module_maps[fnl_path] = nil
  return nil
end
local function restore_module_map_21(fnl_path)
  local modmap = fnl_path__3emodule_map(uri_encode(fnl_path))
  module_maps[fnl_path] = modmap
  return nil
end
return {["log-module-map!"] = log_module_map_21, ["fnl-path->entry-map"] = fnl_path__3eentry_map, ["fnl-path->dependent-map"] = fnl_path__3edependent_map, ["fnl-path->lua-path"] = fnl_path__3elua_path, ["clear-module-map!"] = clear_module_map_21, ["restore-module-map!"] = restore_module_map_21}
