local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local assert_is_file_readable = _local_1_["assert-is-file-readable"]
local read_file = _local_1_["read-file"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local _local_3_ = require("thyme.utils.general")
local validate_type = _local_3_["validate-type"]
local sorter_2ffiles_to_oldest_by_birthtime = _local_3_["sorter/files-to-oldest-by-birthtime"]
local _local_4_ = require("thyme.utils.pool")
local hide_file_21 = _local_4_["hide-file!"]
local has_hidden_file_3f = _local_4_["has-hidden-file?"]
local restore_file_21 = _local_4_["restore-file!"]
local RollbackManager = {_root = Path.join(state_prefix, "rollbacks"), ["_active-backup-filename"] = ".active", ["_pinned-backup-filename"] = ".pinned", ["_mounted-backup-filename"] = ".mounted"}
RollbackManager.__index = RollbackManager
local function symlink_21(path, new_path, ...)
  if file_readable_3f(new_path) then
    hide_file_21(new_path)
  else
  end
  local _6_, _7_ = nil, nil
  local function _8_()
    return vim.uv.fs_symlink(path, new_path)
  end
  _6_, _7_ = pcall(assert(_8_))
  if ((_6_ == false) and (nil ~= _7_)) then
    local msg = _7_
    if has_hidden_file_3f(new_path) then
      return true
    else
      restore_file_21(new_path)
      vim.notify(msg, vim.log.levels.ERROR)
      return false
    end
  else
    local _ = _6_
    return true
  end
end
RollbackManager["module-name->backup-dir"] = function(self, module_name)
  local dir = Path.join(self["_labeled-root"], module_name)
  return dir
end
RollbackManager["module-name->backup-files"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  return vim.fn.glob(Path.join(backup_dir, "*"), false, true)
end
RollbackManager["module-name->new-backup-path"] = function(self, module_name)
  local rollback_id = (os.date("%Y-%m-%d_%H-%M-%S") .. "_" .. vim.uv.hrtime())
  local backup_filename = (rollback_id .. self["file-extension"])
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  vim.fn.mkdir(backup_dir, "p")
  return Path.join(backup_dir, backup_filename)
end
RollbackManager["module-name->active-backup-path"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  local active_backup_filename = RollbackManager["_active-backup-filename"]
  return Path.join(backup_dir, active_backup_filename)
end
RollbackManager["should-update-backup?"] = function(self, module_name, expected_contents)
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local backup_path = self["module-name->active-backup-path"](self, module_name)
  return (not file_readable_3f(backup_path) or (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`")))
end
RollbackManager["cleanup-old-backups!"] = function(self, module_name)
  local _let_11_ = require("thyme.config")
  local get_config = _let_11_["get-config"]
  local config = get_config()
  local max_rollbacks = config["max-rollbacks"]
  validate_type("number", max_rollbacks)
  local threshold = (max_rollbacks + 1)
  local backup_files = self["module-name->backup-files"](self, module_name)
  table.sort(backup_files, sorter_2ffiles_to_oldest_by_birthtime)
  for i = threshold, #backup_files do
    local path = backup_files[i]
    assert(fs.unlink(path))
  end
  return nil
end
RollbackManager["create-module-backup!"] = function(self, module_name, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local backup_path = self["module-name->new-backup-path"](self, module_name)
  local active_backup_path = self["module-name->active-backup-path"](self, module_name)
  vim.fn.mkdir(vim.fs.dirname(active_backup_path), "p")
  assert(fs.copyfile(path, backup_path))
  return symlink_21(backup_path, active_backup_path)
end
RollbackManager["arrange-loader-path"] = function(self, old_loader_path)
  local loader_path_for_mounted_backups = Path.join(self["_labeled-root"], "?", self["_mounted-backup-filename"])
  local loader_prefix = (loader_path_for_mounted_backups .. ";")
  local _12_, _13_ = old_loader_path:find(loader_path_for_mounted_backups, 1, true)
  if (_12_ == 1) then
    return old_loader_path
  elseif (_12_ == nil) then
    return (loader_prefix .. old_loader_path)
  elseif ((nil ~= _12_) and (nil ~= _13_)) then
    local idx_start = _12_
    local idx_end = _13_
    local tmp_loader_path = (old_loader_path:sub(1, idx_start) .. old_loader_path:sub(idx_end))
    return (loader_prefix .. tmp_loader_path)
  else
    return nil
  end
end
RollbackManager.new = function(label, file_extension)
  _G.assert((nil ~= file_extension), "Missing argument file-extension on fnl/thyme/utils/rollback.fnl:140")
  _G.assert((nil ~= label), "Missing argument label on fnl/thyme/utils/rollback.fnl:140")
  local self = setmetatable({}, RollbackManager)
  local root = Path.join(RollbackManager._root, label)
  vim.fn.mkdir(root, "p")
  self._label = label
  self["_labeled-root"] = root
  assert(("." == file_extension:sub(1, 1)), "file-extension must start with `.`")
  self["file-extension"] = file_extension
  return self
end
RollbackManager["get-root"] = function()
  return RollbackManager._root
end
RollbackManager["switch-active-backup!"] = function(backup_path)
  _G.assert((nil ~= backup_path), "Missing argument backup-path on fnl/thyme/utils/rollback.fnl:156")
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
RollbackManager["pin-backup!"] = function(backup_dir)
  local active_backup_path = Path.join(backup_dir, RollbackManager["_active-backup-filename"])
  local pinned_backup_path = Path.join(backup_dir, RollbackManager["_pinned-backup-filename"])
  return symlink_21(active_backup_path, pinned_backup_path)
end
RollbackManager["unpin-backup!"] = function(backup_dir)
  local pinned_backup_path = Path.join(backup_dir, RollbackManager["_pinned-backup-prefix"])
  assert_is_file_readable(pinned_backup_path)
  return assert(fs.unlink(pinned_backup_path))
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
RollbackManager["get-mounted-rollbacks"] = function()
  return vim.fn.glob(Path.join(RollbackManager._root, "*", "*", RollbackManager["_mounted-backup-filename"]), false, true)
end
RollbackManager["unmount-backup-all!"] = function()
  do
    local _15_ = RollbackManager["get-mounted-rollbacks"]()
    if (nil ~= _15_) then
      local mounted_backup_paths = _15_
      for _, path in ipairs(mounted_backup_paths) do
        assert(fs.unlink(path))
      end
    else
    end
  end
  return true
end
return RollbackManager
