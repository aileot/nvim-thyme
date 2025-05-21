local _local_1_ = require("thyme.const")
local state_prefix = _local_1_["state-prefix"]
local Path = require("thyme.utils.path")
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local read_file = _local_2_["read-file"]
local write_log_file_21 = _local_2_["write-log-file!"]
local _local_3_ = require("thyme.utils.uri")
local uri_encode = _local_3_["uri-encode"]
local _local_4_ = require("thyme.utils.iterator")
local each_file = _local_4_["each-file"]
local _local_5_ = require("thyme.utils.pool")
local hide_file_21 = _local_5_["hide-file!"]
local restore_file_21 = _local_5_["restore-file!"]
local can_restore_file_3f = _local_5_["can-restore-file?"]
local HashMap = require("thyme.utils.hashmap")
local modmap_prefix = Path.join(state_prefix, "modmap")
vim.fn.mkdir(modmap_prefix, "p")
local ModuleMap = {}
ModuleMap.__index = ModuleMap
ModuleMap.new = function(_6_)
  local module_name = _6_["module-name"]
  local fnl_path = _6_["fnl-path"]
  local lua_path = _6_["lua-path"]
  assert(module_name, "expected module-name")
  assert(fnl_path, "expected fnl-path")
  local self = setmetatable({}, ModuleMap)
  self["_entry-map"] = {["module-name"] = module_name, ["fnl-path"] = fnl_path, ["lua-path"] = lua_path, ["macro?"] = (nil == lua_path)}
  self["_dependent-maps"] = {}
  self["_log-path"] = ModuleMap["determine-log-path"](fnl_path)
  return self
end
ModuleMap["try-read-from-file"] = function(raw_fnl_path)
  assert_is_file_readable(raw_fnl_path)
  local self = setmetatable({}, ModuleMap)
  local id = ModuleMap["fnl-path->path-id"](raw_fnl_path)
  local log_path = ModuleMap["determine-log-path"](raw_fnl_path)
  if file_readable_3f(log_path) then
    local encoded = read_file(log_path)
    local logged_maps = vim.mpack.decode(encoded)
    local entry_map = logged_maps[id]
    self["_entry-map"] = entry_map
    logged_maps[id] = nil
    self["_dependent-maps"] = logged_maps
    self["_log-path"] = ModuleMap["determine-log-path"](log_path)
    return self
  else
    return nil
  end
end
ModuleMap["get-log-path"] = function(self)
  return self["_log-path"]
end
ModuleMap["get-entry-map"] = function(self)
  return self["_entry-map"]
end
ModuleMap["get-module-name"] = function(self)
  local t_8_ = self["_entry-map"]
  if (nil ~= t_8_) then
    t_8_ = t_8_["module-name"]
  else
  end
  return t_8_
end
ModuleMap["get-fnl-path"] = function(self)
  return self["_entry-map"]["fnl-path"]
end
ModuleMap["get-lua-path"] = function(self)
  return self["_entry-map"]["lua-path"]
end
ModuleMap["macro?"] = function(self)
  return (self["_entry-map"] and self["_entry-map"]["macro?"])
end
ModuleMap["get-dependent-maps"] = function(self)
  return self["_dependent-maps"]
end
ModuleMap["write-file!"] = function(self)
  local log_path = self["get-log-path"](self)
  local entry_map = self["get-entry-map"](self)
  local dependent_maps = self["get-dependent-maps"](self)
  local entry_id = self["fnl-path->path-id"](self["get-fnl-path"](self))
  local _
  dependent_maps[entry_id] = entry_map
  _ = nil
  local encoded = vim.mpack.encode(dependent_maps)
  dependent_maps[entry_id] = nil
  if can_restore_file_3f(log_path, encoded) then
    restore_file_21(log_path)
  else
    write_log_file_21(log_path, encoded)
  end
  return self
end
ModuleMap["log-dependent!"] = function(self, dependent)
  local dep_maps = self["get-dependent-maps"](self)
  local id = self["fnl-path->path-id"](dependent["fnl-path"])
  if not dep_maps[id] then
    dep_maps[id] = dependent
    return self["write-file!"](self)
  else
    return nil
  end
end
ModuleMap["clear!"] = function(self)
  local log_path = self["get-log-path"](self)
  local dep_map = self["get-dependent-maps"](self)
  self["__entry-map"] = self["_entry-map"]
  dep_map["clear!"](dep_map)
  self["_entry-map"] = nil
  return hide_file_21(log_path)
end
ModuleMap["restore!"] = function(self)
  local log_path = self["get-log-path"](self)
  local dep_map = self["get-dependent-maps"](self)
  self["_entry-map"] = self["__entry-map"]
  dep_map["restore!"](dep_map)
  return restore_file_21(log_path)
end
ModuleMap["fnl-path->path-id"] = function(raw_fnl_path)
  assert_is_file_readable(raw_fnl_path)
  return vim.fn.resolve(raw_fnl_path)
end
ModuleMap["determine-log-path"] = function(raw_path)
  assert_is_file_readable(raw_path)
  local id = ModuleMap["fnl-path->path-id"](raw_path)
  local log_id = uri_encode(id)
  return Path.join(modmap_prefix, (log_id .. ".log"))
end
ModuleMap["has-log?"] = function(raw_path)
  local log_path = ModuleMap["determine-log-path"](raw_path)
  return file_readable_3f(log_path)
end
ModuleMap["clear-module-map-files!"] = function()
  return each_file(hide_file_21, modmap_prefix)
end
ModuleMap["get-root"] = function()
  return modmap_prefix
end
return ModuleMap
