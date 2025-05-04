local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local assert_is_file_readable = _local_1_["assert-is-file-readable"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local _local_3_ = require("thyme.utils.pool")
local hide_file_21 = _local_3_["hide-file!"]
local has_hidden_file_3f = _local_3_["has-hidden-file?"]
local restore_file_21 = _local_3_["restore-file!"]
local BackupHandler = require("thyme.rollback.backup-handler")
local RollbackManager = {_root = Path.join(state_prefix, "rollbacks"), ["_active-backup-filename"] = ".active", ["_mounted-backup-filename"] = ".mounted"}
RollbackManager.__index = RollbackManager
local function symlink_21(path, new_path, ...)
  if file_readable_3f(new_path) then
    hide_file_21(new_path)
  else
  end
  local _5_, _6_ = nil, nil
  local function _7_()
    return vim.uv.fs_symlink(path, new_path)
  end
  _5_, _6_ = pcall(assert(_7_))
  if ((_5_ == false) and (nil ~= _6_)) then
    local msg = _6_
    if has_hidden_file_3f(new_path) then
      return true
    else
      restore_file_21(new_path)
      vim.notify(msg, vim.log.levels.ERROR)
      return false
    end
  else
    local _ = _5_
    return true
  end
end
RollbackManager.backupHandlerOf = function(self, module_name)
  return BackupHandler.new(self["_kind-dir"], self["file-extension"], module_name)
end
RollbackManager["arrange-loader-path"] = function(self, old_loader_path)
  local loader_path_for_mounted_backups = Path.join(self["_kind-dir"], "?", self["_mounted-backup-filename"])
  local loader_prefix = (loader_path_for_mounted_backups .. ";")
  local _10_, _11_ = old_loader_path:find(loader_path_for_mounted_backups, 1, true)
  if (_10_ == 1) then
    return old_loader_path
  elseif (_10_ == nil) then
    return (loader_prefix .. old_loader_path)
  elseif ((nil ~= _10_) and (nil ~= _11_)) then
    local idx_start = _10_
    local idx_end = _11_
    local tmp_loader_path = (old_loader_path:sub(1, idx_start) .. old_loader_path:sub(idx_end))
    return (loader_prefix .. tmp_loader_path)
  else
    return nil
  end
end
RollbackManager["search-module-from-mounted-backups"] = function(self, module_name)
  local backup_handler = self:backupHandlerOf(module_name)
  local rollback_path = backup_handler["determine-mounted-backup-path"](backup_handler)
  local loader_name = ("thyme-mounted-rollback-%s-loader"):format(self._kind)
  if file_readable_3f(rollback_path) then
    local resolved_path = fs.readlink(rollback_path)
    local msg = ("%s: rollback to backup for %s (created at %s)"):format(loader_name, module_name, backup_handler["determine-active-backup-birthtime"](backup_handler, module_name))
    vim.notify_once(msg, vim.log.levels.WARN)
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
    local function _15_(...)
      return self["search-module-from-mounted-backups"](self, ...)
    end
    self["_injected-searcher"] = _15_
    return table.insert(searchers, 1, self["_injected-searcher"])
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
  _G.assert((nil ~= file_extension), "Missing argument file-extension on fnl/thyme/rollback/init.fnl:109")
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/rollback/init.fnl:109")
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
  _G.assert((nil ~= backup_path), "Missing argument backup-path on fnl/thyme/rollback/init.fnl:129")
  assert_is_file_readable(backup_path)
  local dir = vim.fs.dirname(backup_path)
  local active_backup_path = Path.join(dir, RollbackManager["_active-backup-filename"])
  return symlink_21(backup_path, active_backup_path)
end
RollbackManager["active-backup?"] = function(backup_path)
  assert_is_file_readable(backup_path)
  local dir = vim.fs.dirname(backup_path)
  local active_backup_path = Path.join(dir, RollbackManager["_active-backup-filename"])
  return (backup_path == fs.readlink(active_backup_path))
end
RollbackManager["mount-backup!"] = function(backup_dir)
  local active_backup_path = Path.join(backup_dir, RollbackManager["_active-backup-filename"])
  local mounted_backup_path = Path.join(backup_dir, RollbackManager["_mounted-backup-filename"])
  return symlink_21(active_backup_path, mounted_backup_path)
end
RollbackManager["unmount-backup!"] = function(backup_dir)
  local mounted_backup_path = Path.join(backup_dir, RollbackManager["_mounted-backup-filename"])
  assert_is_file_readable(mounted_backup_path)
  return assert(fs.unlink(mounted_backup_path))
end
RollbackManager["get-mounted-paths"] = function()
  return vim.fn.glob(Path.join(RollbackManager._root, "*", "*", RollbackManager["_mounted-backup-filename"]), false, true)
end
RollbackManager["unmount-backup-all!"] = function()
  do
    local _18_ = RollbackManager["get-mounted-paths"]()
    if (nil ~= _18_) then
      local mounted_backup_paths = _18_
      for _, path in ipairs(mounted_backup_paths) do
        assert(fs.unlink(path))
      end
    else
    end
  end
  return true
end
return RollbackManager
