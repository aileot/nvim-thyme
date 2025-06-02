local _local_1_ = require("thyme.const")
local state_prefix = _local_1_["state-prefix"]
local Path = require("thyme.util.path")
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local assert_is_log_file = _local_2_["assert-is-log-file"]
local read_file = _local_2_["read-file"]
local write_log_file_21 = _local_2_["write-log-file!"]
local _local_3_ = require("thyme.util.uri")
local uri_encode = _local_3_["uri-encode"]
local uri_decode = _local_3_["uri-decode"]
local _local_4_ = require("thyme.util.iterator")
local each_file = _local_4_["each-file"]
local _local_5_ = require("thyme.util.pool")
local hide_file_21 = _local_5_["hide-file!"]
local restore_file_21 = _local_5_["restore-file!"]
local has_hidden_file_3f = _local_5_["has-hidden-file?"]
local can_restore_file_3f = _local_5_["can-restore-file?"]
local modmap_prefix = Path.join(state_prefix, "modmap")
vim.fn.mkdir(modmap_prefix, "p")
local ModuleMap = {}
ModuleMap.__index = ModuleMap
ModuleMap["get-root"] = function()
  return modmap_prefix
end
ModuleMap["clear-module-map-files!"] = function()
  return each_file(hide_file_21, modmap_prefix)
end
ModuleMap["fnl-path->path-id"] = function(raw_fnl_path)
  assert_is_file_readable(raw_fnl_path)
  return vim.fn.resolve(raw_fnl_path)
end
ModuleMap["determine-log-path"] = function(raw_path)
  assert_is_file_readable(raw_path)
  assert((".log" ~= raw_path:sub(-4)), ".log file is not allowed")
  local id = ModuleMap["fnl-path->path-id"](raw_path)
  local log_id = uri_encode(id)
  return Path.join(modmap_prefix, (log_id .. ".log"))
end
ModuleMap["log-path->path-id"] = function(log_path)
  assert_is_log_file(log_path)
  local decoded = uri_decode(log_path)
  local path_id = assert(assert(decoded:match("^(.+)%.log$"), ("log-path must end with .log, got %s"):format(log_path)):match(("^" .. modmap_prefix .. "/(.+)$")), ("log-path must start with %s, got %s"):format(modmap_prefix, log_path))
  return path_id
end
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
ModuleMap.decode = function(encoded, path_id)
  local logged_maps = vim.mpack.decode(encoded)
  local entry_map = logged_maps[path_id]
  local self = ModuleMap.new({["module-name"] = entry_map["module-name"], ["fnl-path"] = entry_map["fnl-path"], ["lua-path"] = entry_map["lua-path"]})
  logged_maps[path_id] = nil
  if (logged_maps == vim.empty_dict()) then
    self["_dependent-maps"] = {}
  else
    self["_dependent-maps"] = logged_maps
  end
  return self
end
ModuleMap["try-read-from-file"] = function(raw_fnl_path)
  assert_is_file_readable(raw_fnl_path)
  local log_path = ModuleMap["determine-log-path"](raw_fnl_path)
  if file_readable_3f(log_path) then
    local encoded = read_file(log_path)
    local path_id = ModuleMap["fnl-path->path-id"](raw_fnl_path)
    return ModuleMap.decode(encoded, path_id)
  else
    return nil
  end
end
ModuleMap["read-from-log-file"] = function(log_path)
  assert_is_file_readable(log_path)
  assert_is_log_file(log_path)
  local path_id = ModuleMap["log-path->path-id"](log_path)
  return ModuleMap["try-read-from-file"](path_id)
end
ModuleMap.encode = function(self)
  local entry_map = self["get-entry-map"](self)
  local dependent_maps = self["get-dependent-maps"](self)
  local entry_id = self["fnl-path->path-id"](self["get-fnl-path"](self))
  local _
  dependent_maps[entry_id] = entry_map
  _ = nil
  local encoded = vim.mpack.encode(dependent_maps)
  dependent_maps[entry_id] = nil
  return encoded
end
ModuleMap["get-log-path"] = function(self)
  return self["_log-path"]
end
ModuleMap["get-entry-map"] = function(self)
  return self["_entry-map"]
end
ModuleMap["get-module-name"] = function(self)
  return self["get-entry-map"](self)["module-name"]
end
ModuleMap["get-fnl-path"] = function(self)
  return self["get-entry-map"](self)["fnl-path"]
end
ModuleMap["get-lua-path"] = function(self)
  return self["get-entry-map"](self)["lua-path"]
end
ModuleMap["macro?"] = function(self)
  return self["_entry-map"]["macro?"]
end
ModuleMap["get-dependent-maps"] = function(self)
  return self["_dependent-maps"]
end
ModuleMap["pp-module-map"] = function(self)
  local _9_
  if self["macro?"](self) then
    _9_ = "true"
  else
    _9_ = "false"
  end
  return ("  - {:module-name %s\n     :macro? %s\n     :fnl-path %s\n     :lua-path %s"):format(self["get-module-name"](self), _9_, self["get-fnl-path"](self), self["get-lua-path"](self))
end
ModuleMap["pp-dependent-list"] = function(self)
  local entries = {}
  for _, depmap in pairs(self["get-dependent-maps"](self)) do
    local map = ModuleMap.new(depmap)
    local new_entry = map["pp-module-map"](map)
    table.insert(entries, new_entry)
  end
  return table.concat(entries, "\n")
end
ModuleMap["write-file!"] = function(self)
  local log_path = self["get-log-path"](self)
  local encoded = self:encode()
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
ModuleMap["hide!"] = function(self)
  local lua_path = self["get-lua-path"](self)
  local log_path = self["get-log-path"](self)
  self["__entry-map"] = self["_entry-map"]
  self["__dependent-maps"] = self["_dependent-maps"]
  self["_dependent-maps"] = nil
  self["_entry-map"] = nil
  if file_readable_3f(lua_path) then
    hide_file_21(lua_path)
  else
  end
  if file_readable_3f(log_path) then
    return hide_file_21(log_path)
  else
    return nil
  end
end
ModuleMap["restorable?"] = function(self)
  return self["__entry-map"]
end
ModuleMap["restore!"] = function(self)
  local lua_path = self["get-lua-path"](self)
  local log_path = self["get-log-path"](self)
  if self["__entry-map"] then
    self["_entry-map"] = self["__entry-map"]
    self["_dependent-maps"] = self["__dependent-maps"]
    self["__dependent-maps"] = nil
    self["__entry-map"] = nil
  else
  end
  if has_hidden_file_3f(lua_path) then
    restore_file_21(lua_path)
  else
  end
  if has_hidden_file_3f(log_path) then
    return restore_file_21(log_path)
  else
    return nil
  end
end
return ModuleMap
