local ModuleMap = require("thyme.module-map.unit")
local _local_1_ = require("thyme.utils.uri")
local uri_encode = _local_1_["uri-encode"]
local module_maps = {}
local function fnl_path__3emodule_map(fnl_path)
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/thyme/module-map/logger.fnl:9")
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
local function log_module_map_21(dependency)
  local or_5_ = rawget(module_maps, dependency["fnl-path"])
  if not or_5_ then
    local modmap = ModuleMap.new(dependency["fnl-path"])
    if not modmap["logged?"](modmap) then
      modmap["initialize-module-map!"](modmap, dependency)
    else
    end
    module_maps[dependency["fnl-path"]] = modmap
    or_5_ = modmap
  end
  return or_5_
end
local function fnl_path__3eentry_map(fnl_path)
  local tgt_8_ = fnl_path__3emodule_map(fnl_path)
  return (tgt_8_)["get-entry-map"](tgt_8_)
end
local function fnl_path__3edependent_map(fnl_path)
  local tgt_9_ = fnl_path__3emodule_map(fnl_path)
  return (tgt_9_)["get-dependent-maps"](tgt_9_)[fnl_path]
end
local function fnl_path__3elua_path(fnl_path)
  local _10_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _10_) then
    local modmap = _10_
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
