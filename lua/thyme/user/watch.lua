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
local _local_4_ = require("thyme.searcher.macro-module")
local hide_macro_cache_21 = _local_4_["hide-macro-cache!"]
local restore_macro_cache_21 = _local_4_["restore-macro-cache!"]
local _local_5_ = require("thyme.searcher.runtime-module")
local write_lua_file_with_backup_21 = _local_5_["write-lua-file-with-backup!"]
local RuntimeModuleRollbackManager = _local_5_["RuntimeModuleRollbackManager"]
local _local_6_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_6_["clear-cache!"]
local _local_7_ = require("thyme.wrapper.fennel")
local compile_file = _local_7_["compile-file"]
local WatchMessenger = Messenger.new("watch")
local Watcher = {}
Watcher.__index = Watcher
Watcher["get-fnl-path"] = function(self)
  return self["_fnl-path"]
end
Watcher["get-modmap"] = function(self)
  do
    local _8_ = Modmap["try-read-from-file"](self["get-fnl-path"](self))
    if (nil ~= _8_) then
      local latest_modmap = _8_
      self._modmap = latest_modmap
    else
    end
  end
  return self._modmap
end
Watcher["get-lua-path"] = function(self)
  local tgt_10_ = self["get-modmap"](self)
  return (tgt_10_)["get-lua-path"](tgt_10_)
end
Watcher["get-module-name"] = function(self)
  local tgt_11_ = self["get-modmap"](self)
  return (tgt_11_)["get-module-name"](tgt_11_)
end
Watcher["get-depentent-maps"] = function(self)
  local tgt_12_ = self["get-modmap"](self)
  return (tgt_12_)["get-depentent-maps"](tgt_12_)
end
Watcher["macro?"] = function(self)
  local tgt_13_ = self["get-modmap"](self)
  return (tgt_13_)["macro?"](tgt_13_)
end
Watcher["hide-macro-module!"] = function(self)
  local module_name = self["get-module-name"](self)
  return hide_macro_cache_21(module_name)
end
Watcher["restore-macro-module!"] = function(self)
  local module_name = self["get-module-name"](self)
  return restore_macro_cache_21(module_name)
end
Watcher["should-update?"] = function(self)
  local modmap = self["get-modmap"](self)
  if modmap["macro?"](modmap) then
    return true
  else
    local _14_ = modmap["get-lua-path"](modmap)
    if (nil ~= _14_) then
      local lua_path = _14_
      if file_readable_3f(lua_path) then
        local fnl_path = modmap["get-fnl-path"](modmap)
        return (read_file(lua_path) ~= compile_file(fnl_path))
      else
        return nil
      end
    else
      local _ = _14_
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
  local last_chunk = package.loaded[module_name]
  assert(not modmap["macro?"](modmap), "Invalid attempt to recompile macro")
  compiler_options["module-name"] = module_name
  modmap["clear!"](modmap, fnl_path)
  local _18_, _19_ = DepObserver["observe!"](DepObserver, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_18_ == true) and (nil ~= _19_)) then
    local lua_code = _19_
    local msg = ("successfully recompiled " .. fnl_path)
    local backup_handler = RuntimeModuleRollbackManager["backup-handler-of"](RuntimeModuleRollbackManager, module_name)
    write_lua_file_with_backup_21(lua_path, lua_code, module_name)
    backup_handler["cleanup-old-backups!"](backup_handler)
    WatchMessenger["notify!"](WatchMessenger, msg)
    return true
  elseif (true and (nil ~= _19_)) then
    local _ = _18_
    local error_msg = _19_
    local msg = ("abort recompiling %s due to the following error:\n%s"):format(fnl_path, error_msg)
    WatchMessenger["notify!"](WatchMessenger, msg, vim.log.levels.WARN)
    package.loaded[module_name] = last_chunk
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
    local _21_, _22_ = pcall(require, modname)
    if (_21_ == true) then
      return WatchMessenger["notify!"](WatchMessenger, ("Successfully reloaded " .. modname))
    elseif ((_21_ == false) and (nil ~= _22_)) then
      local error_msg = _22_
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
    local _26_, _27_ = raw_strategy:match("^(%S-%-)(%S+)$")
    if ((_26_ == "always-") and (nil ~= _27_)) then
      local strategy0 = _27_
      always_3f, strategy = true, strategy0
    else
      local _ = _26_
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
      local macro_3f = self["macro?"](self)
      local modmap0 = self["get-modmap"](self)
      local dependent_maps = modmap0["get-dependent-maps"](modmap0)
      if macro_3f then
        self["hide-macro-module!"](self)
      else
      end
      if modmap0["clear!"](modmap0) then
        WatchMessenger["notify!"](WatchMessenger, ("Cleared the cache for " .. self["get-fnl-path"](self)))
      else
      end
      self["update-dependent-modules!"](dependent_maps)
      if macro_3f then
        return self["restore-macro-module!"](self)
      else
        return nil
      end
    elseif (final_strategy == "recompile") then
      local macro_3f = self["macro?"](self)
      local dependent_maps = modmap["get-dependent-maps"](modmap)
      if macro_3f then
        self["hide-macro-module!"](self)
      else
        self["try-recompile!"](self)
      end
      self["update-dependent-modules!"](dependent_maps)
      if macro_3f then
        return self["restore-macro-module!"](self)
      else
        return nil
      end
    elseif (final_strategy == "reload") then
      local macro_3f = self["macro?"](self)
      local dependent_maps = modmap["get-dependent-maps"](modmap)
      if macro_3f then
        self["hide-macro-module!"](self)
      else
        self["try-reload!"](self)
      end
      return self["update-dependent-modules!"](dependent_maps)
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
    local function _39_()
      local tgt_40_ = Modmap["try-read-from-file"](dependent_fnl_path)
      return (tgt_40_)["clear!"](tgt_40_)
    end
    vim.schedule(_39_)
  end
  return nil
end
Watcher["restore-dependent-module-maps!"] = function(self)
  local modmap = self["get-modmap"](self)
  local dependent_maps = modmap["get-dependent-maps"](modmap)
  for dependent_fnl_path in pairs(dependent_maps) do
    local function _41_()
      local modmap0 = Modmap.new(dependent_fnl_path)
      if modmap0["restorable?"](modmap0) then
        return modmap0["restore!"](modmap0)
      else
        return nil
      end
    end
    vim.schedule(_41_)
  end
  return nil
end
Watcher["update-dependent-modules!"] = function(dependent_maps)
  for _, dependent in pairs(dependent_maps) do
    if file_readable_3f(dependent["fnl-path"]) then
      local tgt_43_ = Watcher.new(dependent["fnl-path"])
      do end (tgt_43_)["update!"](tgt_43_)
    else
    end
  end
  return nil
end
Watcher.new = function(fnl_path)
  assert_is_fnl_file(fnl_path)
  local self = setmetatable({}, Watcher)
  self["_fnl-path"] = fnl_path
  local _45_ = Modmap["try-read-from-file"](fnl_path)
  if (nil ~= _45_) then
    local modmap = _45_
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
  local function _48_(_47_)
    local fnl_path = _47_["match"]
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
      local _51_ = Watcher.new(fnl_path)
      if (nil ~= _51_) then
        local watcher = _51_
        watcher["update!"](watcher)
      else
      end
    end
    return nil
  end
  callback = _48_
  return vim.api.nvim_create_autocmd(opts.event, {group = group, pattern = opts.pattern, callback = callback})
end
return {["watch-files!"] = watch_files_21}
