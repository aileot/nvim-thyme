local _local_1_ = require("thyme.const")
local config_path = _local_1_["config-path"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_fnl_file = _local_2_["assert-is-fnl-file"]
local read_file = _local_2_["read-file"]
local _local_3_ = require("thyme.util.trust")
local allowed_3f = _local_3_["allowed?"]
local Messenger = require("thyme.util.class.messenger")
local Config = require("thyme.config")
local Modmap = require("thyme.dependency.unit")
local DepObserver = require("thyme.dependency.observer")
local _local_4_ = require("thyme.searcher.runtime-module")
local write_lua_file_with_backup_21 = _local_4_["write-lua-file-with-backup!"]
local RuntimeModuleRollbackManager = _local_4_["RuntimeModuleRollbackManager"]
local _local_5_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_5_["clear-cache!"]
local _local_6_ = require("thyme.wrapper.fennel")
local compile_file = _local_6_["compile-file"]
local WatchMessenger = Messenger.new("watch")
local _3fgroup = nil
local Watcher = {}
Watcher.__index = Watcher
Watcher["get-modmap"] = function(self)
  do
    local _7_ = Modmap["try-read-from-file"](self["_fnl-path"])
    if (nil ~= _7_) then
      local latest_modmap = _7_
      self._modmap = latest_modmap
    else
    end
  end
  return self._modmap
end
Watcher["get-lua-path"] = function(self)
  local tgt_9_ = self["get-modmap"](self)
  return (tgt_9_)["get-lua-path"](tgt_9_)
end
Watcher["get-module-name"] = function(self)
  local tgt_10_ = self["get-modmap"](self)
  return (tgt_10_)["get-module-name"](tgt_10_)
end
Watcher["get-depentent-maps"] = function(self)
  local tgt_11_ = self["get-modmap"](self)
  return (tgt_11_)["get-depentent-maps"](tgt_11_)
end
Watcher["macro?"] = function(self)
  local tgt_12_ = self["get-modmap"](self)
  return (tgt_12_)["macro?"](tgt_12_)
end
Watcher["should-update?"] = function(self)
  local modmap = self["get-modmap"](self)
  if modmap["macro?"](modmap) then
    return true
  else
    local _13_ = modmap["get-lua-path"](modmap)
    if (nil ~= _13_) then
      local lua_path = _13_
      if file_readable_3f(lua_path) then
        local fnl_path = modmap["get-fnl-path"](modmap)
        return (read_file(lua_path) ~= compile_file(fnl_path))
      else
        return nil
      end
    else
      local _ = _13_
      return error(("invalid ModuleMap instance for %s: %s"):format(modmap["get-module-name"](modmap), vim.inspect(modmap)))
    end
  end
end
Watcher["count-dependent-modules"] = function(self)
  local modmap = self["get-modmap"](self)
  local dependent_maps = modmap["get-dependent-maps"](modmap)
  local i = 0
  for _ in pairs(dependent_maps) do
    i = i
  end
  return i
end
Watcher["try-recompile!"] = function(self)
  local fennel = require("fennel")
  local compiler_options = Config["compiler-options"]
  local modmap = self["get-modmap"](self)
  local module_name = modmap["get-module-name"](modmap)
  local fnl_path = modmap["get-fnl-path"](modmap)
  local lua_path = modmap["get-lua-path"](modmap)
  assert(not modmap["macro?"](modmap), "Invalid attempt to recompile macro")
  compiler_options["module-name"] = module_name
  modmap["clear!"](modmap, fnl_path)
  local _17_, _18_ = DepObserver["observe!"](DepObserver, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_17_ == true) and (nil ~= _18_)) then
    local lua_code = _18_
    local msg = ("successfully recompiled " .. fnl_path)
    local backup_handler = RuntimeModuleRollbackManager["backup-handler-of"](RuntimeModuleRollbackManager, module_name)
    write_lua_file_with_backup_21(lua_path, lua_code, module_name)
    backup_handler["cleanup-old-backups!"](backup_handler)
    WatchMessenger["notify!"](WatchMessenger, msg)
    return true
  elseif (true and (nil ~= _18_)) then
    local _ = _17_
    local error_msg = _18_
    local msg = ("abort recompiling %s due to the following error:\n%s"):format(fnl_path, error_msg)
    WatchMessenger["notify!"](WatchMessenger, msg, vim.log.levels.WARN)
    modmap["restore!"](modmap)
    return false
  else
    return nil
  end
end
Watcher["try-reload!"] = function(self)
  local modmap = self["get-modmap"](self)
  local modname = modmap["get-module-name"](modmap)
  local last_chunk = package.loaded[modname]
  package.loaded[modname] = nil
  if modmap["macro?"](modmap) then
    local _20_, _21_ = pcall(require, modname)
    if (_20_ == true) then
      return WatchMessenger["notify!"](WatchMessenger, ("Successfully reloaded " .. modname))
    elseif ((_20_ == false) and (nil ~= _21_)) then
      local error_msg = _21_
      local msg = ("Failed to reload %s due to the following error:\n%s"):format(modname, error_msg)
      package.loaded[modname] = last_chunk
      return WatchMessenger["notify!"](WatchMessenger, msg, vim.log.levels.ERROR)
    else
      return nil
    end
  else
    return nil
  end
end
Watcher["update!"] = function(self)
  local modmap = self["get-modmap"](self)
  local raw_strategy
  if modmap["macro?"](modmap) then
    raw_strategy = (Config.watch["macro-strategy"] or Config.watch.strategy)
  else
    raw_strategy = Config.watch.strategy
  end
  local always_3f, strategy = nil, nil
  do
    local _25_, _26_ = raw_strategy:match("^(%S-%-)(%S+)$")
    if ((_25_ == "always-") and (nil ~= _26_)) then
      local strategy0 = _26_
      always_3f, strategy = true, strategy0
    else
      local _ = _25_
      always_3f, strategy = false, raw_strategy
    end
  end
  local final_strategy
  if file_readable_3f(self["get-fnl-path"](self)) then
    final_strategy = strategy
  else
    final_strategy = "clear"
  end
  if (always_3f or self["should-update?"](self)) then
    if (final_strategy == "clear-all") then
      if clear_cache_21() then
        return WatchMessenger["notify!"](WatchMessenger, ("Cleared all the caches under " .. lua_cache_prefix))
      else
        return nil
      end
    elseif (final_strategy == "clear") then
      local modmap0 = self["get-modmap"](self)
      if modmap0["clear!"](modmap0) then
        WatchMessenger["notify!"](WatchMessenger, ("Cleared the cache for " .. modmap0["get-fnl-path"](modmap0)))
      else
      end
      return self["update-dependent-modules!"](self)
    elseif (final_strategy == "recompile") then
      self["clear-dependent-module-maps!"](self)
      if not self["macro?"](self) then
        self["try-recompile!"](self)
      else
      end
      return self["update-dependent-modules!"](self)
    elseif (final_strategy == "reload") then
      self["clear-dependent-module-maps!"](self)
      if not self["macro?"](self) then
        self["try-reload!"](self)
      else
      end
      return self["update-dependent-modules!"](self)
    else
      local _ = final_strategy
      return error(("unsupported strategy: " .. strategy))
    end
  else
    return nil
  end
end
Watcher["clear-dependent-module-maps!"] = function(self)
  local modmap = self["get-modmap"](self)
  local dependent_maps = modmap["get-dependent-maps"](modmap)
  for dependent_fnl_path in pairs(dependent_maps) do
    local function _35_()
      local tgt_36_ = Modmap["try-read-from-file"](dependent_fnl_path)
      return (tgt_36_)["clear!"](tgt_36_)
    end
    vim.schedule(_35_)
  end
  return nil
end
Watcher["restore-dependent-module-maps!"] = function(self)
  local modmap = self["get-modmap"](self)
  local dependent_maps = modmap["get-dependent-maps"](modmap)
  for dependent_fnl_path in pairs(dependent_maps) do
    local function _37_()
      local modmap0 = Modmap.new(dependent_fnl_path)
      if modmap0["restorable?"](modmap0) then
        return modmap0["restore!"](modmap0)
      else
        return nil
      end
    end
    vim.schedule(_37_)
  end
  return nil
end
Watcher["update-dependent-modules!"] = function(self)
  local modmap = self["get-modmap"](self)
  local dependent_maps = modmap["get-dependent-maps"](modmap)
  for _, dependent in pairs(dependent_maps) do
    if file_readable_3f(dependent["fnl-path"]) then
      local tgt_39_ = Watcher.new(dependent["fnl-path"])
      do end (tgt_39_)["update!"](tgt_39_)
    else
    end
  end
  return nil
end
Watcher.new = function(fnl_path)
  assert_is_fnl_file(fnl_path)
  local self = setmetatable({}, Watcher)
  self["_fnl-path"] = fnl_path
  local _41_ = Modmap["try-read-from-file"](fnl_path)
  if (nil ~= _41_) then
    local modmap = _41_
    self._modmap = modmap
    return self
  else
    return nil
  end
end
local function watch_files_21()
  local group = vim.api.nvim_create_augroup("ThymeWatch", {})
  local opts = Config.watch
  local callback
  local function _44_(_43_)
    local fnl_path = _43_["match"]
    local resolved_path = vim.fn.resolve(fnl_path)
    if (config_path == resolved_path) then
      if allowed_3f(config_path) then
        vim.cmd("silent trust")
      else
      end
      if clear_cache_21() then
        local msg = ("Cleared all the cache under " .. lua_cache_prefix)
        WatchMessenger["notify!"](WatchMessenger, msg)
      else
      end
    else
      local _47_ = Watcher.new(fnl_path)
      if (nil ~= _47_) then
        local watcher = _47_
        watcher["update!"](watcher)
      else
      end
    end
    return nil
  end
  callback = _44_
  _3fgroup = group
  return vim.api.nvim_create_autocmd(opts.event, {group = group, pattern = opts.pattern, callback = callback})
end
return {["watch-files!"] = watch_files_21}
