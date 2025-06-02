local Path = require("thyme.util.path")
local _local_1_ = require("thyme.util.fs")
local file_readable_3f = _local_1_["file-readable?"]
local assert_is_symlink = _local_1_["assert-is-symlink"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local Messenger = require("thyme.util.class.messenger")
local BackupHandler = require("thyme.rollback.backup-handler")
local RollbackManager = {_root = Path.join(state_prefix, "rollbacks"), ["_active-backup-filename"] = ".active", ["_mounted-backup-filename"] = ".mounted"}
RollbackManager.__index = RollbackManager
RollbackManager["backup-handler-of"] = function(self, module_name)
  return BackupHandler.new(self["_kind-dir"], self["file-extension"], module_name)
end
RollbackManager["search-module-from-mounted-backups"] = function(self, module_name)
  local backup_handler = self["backup-handler-of"](self, module_name)
  local rollback_path = backup_handler["determine-mounted-backup-path"](backup_handler)
  local messenger = Messenger.new(("loader/%s/rollback/mounted"):format(self._kind))
  if file_readable_3f(rollback_path) then
    local msg = ("rollback to backup for %s (created at %s)"):format(module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name))
    messenger["notify-once!"](messenger, msg, vim.log.levels.WARN)
    return self["_file-loader"](rollback_path, module_name)
  else
    local error_msg = messenger["mk-failure-reason"](messenger, ("no mounted backup is found for %s"):format(module_name))
    if (self._kind == "macro") then
      return nil, error_msg
    else
      return error_msg
    end
  end
end
RollbackManager["inject-mounted-backup-searcher!"] = function(self, searchers, loader)
  if not self["_injected-searcher"] then
    local function _5_(...)
      return self["search-module-from-mounted-backups"](self, ...)
    end
    self["_injected-searcher"] = _5_
    self["_file-loader"] = loader
    table.insert(searchers, 1, self["_injected-searcher"])
    return self["_injected-searcher"]
  elseif (searchers[1] ~= self["_injected-searcher"]) then
    do
      local dropped_3f = false
      for i = 1, #searchers do
        if dropped_3f then break end
        if (searchers[i] == self["_injected-searcher"]) then
          dropped_3f = table.remove(searchers, i)
        else
          dropped_3f = false
        end
      end
    end
    return table.insert(searchers, 1, self["_injected-searcher"])
  else
    return nil
  end
end
RollbackManager["list-backup-dirs"] = function(self)
  return vim.fn.glob(Path.join(self["_kind-dir"], "*"), false, true)
end
RollbackManager["list-backup-modules"] = function(self)
  local paths = self["list-backup-dirs"](self)
  local tbl_21_ = {}
  local i_22_ = 0
  for _, path in ipairs(paths) do
    local val_23_ = vim.fs.basename(path)
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  return tbl_21_
end
RollbackManager.new = function(kind, file_extension)
  _G.assert((nil ~= file_extension), "Missing argument file-extension on fnl/thyme/rollback/manager.fnl:96")
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/rollback/manager.fnl:96")
  local self = setmetatable({}, RollbackManager)
  local root = Path.join(RollbackManager._root, kind)
  vim.fn.mkdir(root, "p")
  self._kind = kind
  self["_kind-dir"] = root
  self["_file-loader"] = {}
  assert(("." == file_extension:sub(1, 1)), "file-extension must start with `.`")
  self["file-extension"] = file_extension
  return self
end
RollbackManager["get-root"] = function()
  return RollbackManager._root
end
RollbackManager["list-mounted-paths"] = function()
  return vim.fn.glob(Path.join(RollbackManager._root, "*", "*", RollbackManager["_mounted-backup-filename"]), false, true)
end
RollbackManager["unmount-backup-all!"] = function()
  do
    local _9_ = RollbackManager["list-mounted-paths"]()
    if (nil ~= _9_) then
      local mounted_backup_paths = _9_
      for _, path in ipairs(mounted_backup_paths) do
        assert_is_symlink(path)
        assert(fs.unlink(path))
      end
    else
    end
  end
  return true
end
return RollbackManager
