local _local_1_ = require("thyme.const")
local state_prefix = _local_1_["state-prefix"]
local Path = require("thyme.utils.path")
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local write_log_file_21 = _local_2_["write-log-file!"]
local append_log_file_21 = _local_2_["append-log-file!"]
local _local_3_ = require("thyme.utils.uri")
local uri_encode = _local_3_["uri-encode"]
local _local_4_ = require("thyme.utils.iterator")
local each_file = _local_4_["each-file"]
local _local_5_ = require("thyme.utils.pool")
local hide_file_21 = _local_5_["hide-file!"]
local restore_file_21 = _local_5_["restore-file!"]
local can_restore_file_3f = _local_5_["can-restore-file?"]
local HashMap = require("thyme.utils.hashmap")
local _local_6_ = require("thyme.dependency.stackframe")
local validate_stackframe_21 = _local_6_["validate-stackframe!"]
local Stackframe = _local_6_
local _local_7_ = require("thyme.dependency.io")
local modmap__3eline = _local_7_["modmap->line"]
local read_module_map_file = _local_7_["read-module-map-file"]
local modmap_prefix = Path.join(state_prefix, "modmap")
vim.fn.mkdir(modmap_prefix, "p")
local ModuleMap = {}
ModuleMap.__index = ModuleMap
ModuleMap.new = function(raw_fnl_path)
  local self = setmetatable({}, ModuleMap)
  local id = ModuleMap["fnl-path->id"](raw_fnl_path)
  local log_path = ModuleMap["determine-log-path"](id)
  local logged_3f = file_readable_3f(log_path)
  local modmap
  if logged_3f then
    modmap = read_module_map_file(log_path)
  else
    modmap = {}
  end
  self["_log-path"] = log_path
  self["_entry-map"] = modmap[id]
  modmap[id] = nil
  self["_dependent-maps"] = HashMap.new()
  return self
end
ModuleMap["try-read-from-file"] = function(raw_fnl_path)
  assert_is_file_readable(raw_fnl_path)
  local self = setmetatable({}, ModuleMap)
  local id = ModuleMap["fnl-path->id"](raw_fnl_path)
  local log_path = ModuleMap["determine-log-path"](id)
  if file_readable_3f(log_path) then
    local _9_ = read_module_map_file(log_path)
    if (nil ~= _9_) then
      local modmap = _9_
      self["_log-path"] = log_path
      self["_entry-map"] = modmap[id]
      modmap[id] = nil
      self["_dep-map"] = modmap
      return self
    else
      return nil
    end
  else
    return nil
  end
end
ModuleMap["initialize-module-map!"] = function(self, _12_)
  local module_name = _12_["module-name"]
  local modmap = _12_
  local modmap_line = modmap__3eline(modmap)
  local log_path = self["get-log-path"](self)
  assert(not file_readable_3f(log_path), ("this method only expects an empty log file for the module " .. module_name))
  if can_restore_file_3f(log_path, modmap_line) then
    restore_file_21(log_path)
  else
    write_log_file_21(log_path, modmap_line)
  end
  self["_entry-map"] = modmap
  return nil
end
ModuleMap["get-log-path"] = function(self)
  return self["_log-path"]
end
ModuleMap["get-entry-map"] = function(self)
  return self["_entry-map"]
end
ModuleMap["get-module-name"] = function(self)
  local t_14_ = self["_entry-map"]
  if (nil ~= t_14_) then
    t_14_ = t_14_["module-name"]
  else
  end
  return t_14_
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
ModuleMap["log-dependent!"] = function(self, dependent)
  local dep_map = self["get-dependent-maps"](self)
  local id = self["fnl-path->id"](dependent["fnl-path"])
  if not dep_map["contains?"](dep_map, id) then
    local modmap_line = modmap__3eline(dependent)
    local log_path = self["get-log-path"](self)
    dep_map["insert!"](dep_map, id, dependent)
    return append_log_file_21(log_path, modmap_line)
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
ModuleMap["fnl-path->id"] = function(raw_fnl_path)
  return vim.fn.resolve(raw_fnl_path)
end
ModuleMap["determine-log-path"] = function(raw_path)
  local id = ModuleMap["fnl-path->id"](raw_path)
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
