local _local_1_ = require("thyme.const")
local state_prefix = _local_1_["state-prefix"]
local Path = require("thyme.utils.path")
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
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
local _local_6_ = require("thyme.dependency.io")
local modmap__3eline = _local_6_["modmap->line"]
local read_module_map_file = _local_6_["read-module-map-file"]
local modmap_prefix = Path.join(state_prefix, "modmap")
vim.fn.mkdir(modmap_prefix, "p")
local ModuleMap = {}
ModuleMap.__index = ModuleMap
ModuleMap.new = function(raw_fnl_path)
  local self = setmetatable({}, ModuleMap)
  local fnl_path = vim.fn.resolve(raw_fnl_path)
  local log_path = ModuleMap["fnl-path->log-path"](fnl_path)
  local logged_3f = file_readable_3f(log_path)
  local modmap
  if logged_3f then
    modmap = read_module_map_file(log_path)
  else
    modmap = {}
  end
  self["_log-path"] = log_path
  self["_entry-map"] = modmap[fnl_path]
  modmap[fnl_path] = nil
  self["_dep-map"] = modmap
  return self
end
ModuleMap["try-read-from-file"] = function(raw_fnl_path)
  local self = setmetatable({}, ModuleMap)
  local fnl_path = vim.fn.resolve(raw_fnl_path)
  local log_path = ModuleMap["fnl-path->log-path"](fnl_path)
  if file_readable_3f(log_path) then
    local _8_ = read_module_map_file(log_path)
    if (nil ~= _8_) then
      local modmap = _8_
      self["_log-path"] = log_path
      self["_entry-map"] = modmap[fnl_path]
      modmap[fnl_path] = nil
      self["_dep-map"] = modmap
      return self
    else
      return nil
    end
  else
    return nil
  end
end
ModuleMap["initialize-module-map!"] = function(self, _11_)
  local module_name = _11_["module-name"]
  local fnl_path = _11_["fnl-path"]
  local _lua_path = _11_["lua-path"]
  local _macro_3f = _11_["macro?"]
  local modmap = _11_
  modmap["fnl-path"] = vim.fn.resolve(fnl_path)
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
  local t_13_ = self["_entry-map"]
  if (nil ~= t_13_) then
    t_13_ = t_13_["module-name"]
  else
  end
  return t_13_
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
  return self["_dep-map"]
end
ModuleMap["log-dependent!"] = function(self, dependent)
  if not self["_dep-map"][dependent["fnl-path"]] then
    local modmap_line = modmap__3eline(dependent)
    local log_path = self["get-log-path"](self)
    self["_dep-map"][dependent["fnl-path"]] = dependent
    return append_log_file_21(log_path, modmap_line)
  else
    return nil
  end
end
ModuleMap["clear!"] = function(self)
  local log_path = self["get-log-path"](self)
  self["__entry-map"] = self["_entry-map"]
  self["__dep-map"] = self["_dep-map"]
  self["_entry-map"] = nil
  self["_dep-map"] = nil
  return hide_file_21(log_path)
end
ModuleMap["restore!"] = function(self)
  local log_path = self["get-log-path"](self)
  self["_entry-map"] = self["__entry-map"]
  self["_dep-map"] = self["__dep-map"]
  return restore_file_21(log_path)
end
ModuleMap["fnl-path->log-path"] = function(raw_path)
  local resolved_path = vim.fn.resolve(raw_path)
  local log_id = uri_encode(resolved_path)
  return Path.join(modmap_prefix, (log_id .. ".log"))
end
ModuleMap["has-log?"] = function(raw_path)
  local log_path = ModuleMap["fnl-path->log-path"](raw_path)
  return file_readable_3f(log_path)
end
ModuleMap["clear-module-map-files!"] = function()
  return each_file(hide_file_21, modmap_prefix)
end
ModuleMap["get-root"] = function()
  return modmap_prefix
end
return ModuleMap
