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
local Config = require("thyme.lazy-config")
local Modmap = require("thyme.dependency.unit")
local DepObserver = require("thyme.dependency.observer")
local _local_4_ = require("thyme.loader.macro-module")
local hide_macro_cache_21 = _local_4_["hide-macro-cache!"]
local restore_macro_cache_21 = _local_4_["restore-macro-cache!"]
local _local_5_ = require("thyme.loader.runtime-module")
local write_lua_file_with_backup_21 = _local_5_["write-lua-file-with-backup!"]
local RuntimeModuleRollbackManager = _local_5_["RuntimeModuleRollbackManager"]
local _local_6_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_6_["clear-cache!"]
local _local_7_ = require("thyme.wrapper.fennel")
local compile_file = _local_7_["compile-file"]
local WatchMessenger = Messenger.new("autocmd/watch")
local Watcher = {}
Watcher.__index = Watcher
Watcher["get-fnl-path"] = function(self)
  return self["_fnl-path"]
end
Watcher["get-modmap"] = function(self)
  do
    local fnl_path = self["get-fnl-path"](self)
    if file_readable_3f(fnl_path) then
      local _8_ = Modmap["try-read-from-file"](fnl_path)
      if (nil ~= _8_) then
        local latest_modmap = _8_
        self._modmap = latest_modmap
      else
      end
    else
    end
  end
  return self._modmap
end
Watcher["get-lua-path"] = function(self)
  local tgt_11_ = self["get-modmap"](self)
  return (tgt_11_)["get-lua-path"](tgt_11_)
end
Watcher["get-module-name"] = function(self)
  local tgt_12_ = self["get-modmap"](self)
  return (tgt_12_)["get-module-name"](tgt_12_)
end
Watcher["get-depentent-maps"] = function(self)
  local tgt_13_ = self["get-modmap"](self)
  return (tgt_13_)["get-depentent-maps"](tgt_13_)
end
Watcher["macro?"] = function(self)
  local tgt_14_ = self["get-modmap"](self)
  return (tgt_14_)["macro?"](tgt_14_)
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
    local _15_ = modmap["get-lua-path"](modmap)
    if (nil ~= _15_) then
      local lua_path = _15_
      if file_readable_3f(lua_path) then
        local fnl_path = modmap["get-fnl-path"](modmap)
        return (read_file(lua_path) ~= compile_file(fnl_path))
      else
        return false
      end
    else
      local _ = _15_
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
  modmap["hide!"](modmap, fnl_path)
  local _19_, _20_ = DepObserver["observe!"](DepObserver, fennel["compile-string"], fnl_path, lua_path, compiler_options, module_name)
  if ((_19_ == true) and (nil ~= _20_)) then
    local lua_code = _20_
    local msg = ("successfully recompiled " .. fnl_path)
    local backup_handler = RuntimeModuleRollbackManager["backup-handler-of"](RuntimeModuleRollbackManager, module_name)
    write_lua_file_with_backup_21(lua_path, lua_code, module_name)
    backup_handler["cleanup-old-backups!"](backup_handler)
    WatchMessenger["notify!"](WatchMessenger, msg)
    return true
  elseif (true and (nil ~= _20_)) then
    local _ = _19_
    local error_msg = _20_
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
    local _22_, _23_ = pcall(require, modname)
    if (_22_ == true) then
      return WatchMessenger["notify!"](WatchMessenger, ("Successfully reloaded " .. modname))
    elseif ((_22_ == false) and (nil ~= _23_)) then
      local error_msg = _23_
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
    local _27_, _28_ = raw_strategy:match("^(%S-%-)(%S+)$")
    if ((_27_ == "always-") and (nil ~= _28_)) then
      local strategy0 = _28_
      always_3f, strategy = true, strategy0
    else
      local _ = _27_
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
      if modmap0["hide!"](modmap0) then
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
Watcher["update-dependent-modules!"] = function(dependent_maps)
  for _, dependent in pairs(dependent_maps) do
    local function _40_()
      if file_readable_3f(dependent["fnl-path"]) then
        local tgt_41_ = Watcher.new(dependent["fnl-path"])
        return (tgt_41_)["update!"](tgt_41_)
      else
        return nil
      end
    end
    vim.schedule(_40_)
  end
  return nil
end
Watcher.new = function(fnl_path)
  assert_is_fnl_file(fnl_path)
  local self = setmetatable({}, Watcher)
  self["_fnl-path"] = fnl_path
  if file_readable_3f(fnl_path) then
    local _43_ = Modmap["try-read-from-file"](fnl_path)
    if (nil ~= _43_) then
      local modmap = _43_
      self._modmap = modmap
      return self
    else
      return nil
    end
  else
    return nil
  end
end
local function watch_files_21()
  local group = vim.api.nvim_create_augroup("ThymeWatch", {})
  local opts = Config.watch
  local callback
  local function _47_(_46_)
    local buf = _46_["buf"]
    local fnl_path = _46_["match"]
    if (("/" == fnl_path:sub(1, 1)) and ("" == vim.bo[buf].buftype)) then
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
        local _50_ = Watcher.new(fnl_path)
        if (nil ~= _50_) then
          local watcher = _50_
          watcher["update!"](watcher)
        else
        end
      end
      return nil
    else
      return nil
    end
  end
  callback = _47_
  return vim.api.nvim_create_autocmd(opts.event, {group = group, pattern = opts.pattern, callback = callback})
end
return {["watch-files!"] = watch_files_21}
