local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local assert_is_file_readable = _local_1_["assert-is-file-readable"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local Messenger = require("thyme.utils.messenger")
local BackupHandler = require("thyme.rollback.backup-handler")
local RollbackManager = {_root = Path.join(state_prefix, "rollbacks"), ["_active-backup-filename"] = ".active", ["_mounted-backup-filename"] = ".mounted"}
RollbackManager.__index = RollbackManager
RollbackManager.backupHandlerOf = function(self, module_name)
  return BackupHandler.new(self["_kind-dir"], self["file-extension"], module_name)
end
RollbackManager["search-module-from-mounted-backups"] = function(self, module_name)
  local backup_handler = self:backupHandlerOf(module_name)
  local rollback_path = backup_handler["determine-mounted-backup-path"](backup_handler)
  local loader_name = ("mounted-rollback-%s-loader"):format(self._kind)
  local messenger = Messenger.new(loader_name)
  if file_readable_3f(rollback_path) then
    local resolved_path = fs.readlink(rollback_path)
    local msg = ("rollback to backup for %s (created at %s)"):format(loader_name, module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name))
    messenger["notify-once!"](messenger, msg, vim.log.levels.WARN)
    return loadfile(resolved_path)
  else
    local error_msg = ("%s: no mounted backup is found for %s %s"):format(loader_name, self._kind, module_name)
    if (self._kind == "macro") then
      return nil, error_msg
    else
      return error_msg
    end
  end
end
RollbackManager["inject-mounted-backup-searcher!"] = function(self, searchers)
  if not self["_injected-searcher"] then
    local function _5_(...)
      return self["search-module-from-mounted-backups"](self, ...)
    end
    self["_injected-searcher"] = _5_
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
RollbackManager.new = function(kind, file_extension)
  _G.assert((nil ~= file_extension), "Missing argument file-extension on fnl/thyme/rollback/init.fnl:79")
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/rollback/init.fnl:79")
  local self = setmetatable({}, RollbackManager)
  local root = Path.join(RollbackManager._root, kind)
  vim.fn.mkdir(root, "p")
  self._kind = kind
  self["_kind-dir"] = root
  assert(("." == file_extension:sub(1, 1)), "file-extension must start with `.`")
  self["file-extension"] = file_extension
  return self
end
RollbackManager["get-root"] = function()
  return RollbackManager._root
end
RollbackManager["switch-active-backup!"] = function(backup_path)
  _G.assert((nil ~= backup_path), "Missing argument backup-path on fnl/thyme/rollback/init.fnl:99")
  assert_is_file_readable(backup_path)
  local dir = vim.fs.dirname(backup_path)
  local active_backup_path = Path.join(dir, RollbackManager["_active-backup-filename"])
  return fs["symlink!"](backup_path, active_backup_path)
end
RollbackManager["active-backup?"] = function(backup_path)
  assert_is_file_readable(backup_path)
  local dir = vim.fs.dirname(backup_path)
  local active_backup_path = Path.join(dir, RollbackManager["_active-backup-filename"])
  return (backup_path == fs.readlink(active_backup_path))
end
RollbackManager["list-mounted-paths"] = function()
  return vim.fn.glob(Path.join(RollbackManager._root, "*", "*", RollbackManager["_mounted-backup-filename"]), false, true)
end
RollbackManager["unmount-backup-all!"] = function()
  do
    local _8_ = RollbackManager["list-mounted-paths"]()
    if (nil ~= _8_) then
      local mounted_backup_paths = _8_
      for _, path in ipairs(mounted_backup_paths) do
        assert(fs.unlink(path))
      end
    else
    end
  end
  return true
end
return RollbackManager
