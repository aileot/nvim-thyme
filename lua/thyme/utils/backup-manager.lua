local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local backup_prefix = Path.join(state_prefix, "backup")
local BackupManager = {}
BackupManager.__index = BackupManager
BackupManager.new = function(label, file_extension)
  _G.assert((nil ~= file_extension), "Missing argument file-extension on fnl/thyme/utils/backup-manager.fnl:14")
  _G.assert((nil ~= label), "Missing argument label on fnl/thyme/utils/backup-manager.fnl:14")
  local self = setmetatable({}, BackupManager)
  local root = Path.join(backup_prefix, label)
  vim.fn.mkdir(root, "p")
  self.root = root
  assert(("." == file_extension:sub(1, 1)), "file-extension must start with `.`")
  self["file-extension"] = file_extension
  return self
end
BackupManager["module-name->backup-dir"] = function(self, module_name)
  local dir = Path.join(self.root, module_name)
  return dir
end
BackupManager["module-name->new-backup-path"] = function(self, module_name)
  local rollback_id = os.date("%Y-%m-%d_%H-%M-%S")
  local backup_filename = (rollback_id .. self["file-extension"])
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  vim.fn.mkdir(backup_dir, "p")
  return Path.join(backup_dir, backup_filename)
end
BackupManager["module-name->current-backup-path"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  local current_backup_filename = (".current" .. self["file-extension"])
  return Path.join(backup_dir, current_backup_filename)
end
BackupManager["should-update-backup?"] = function(self, module_name, expected_contents)
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local backup_path = self["module-name->current-backup-path"](self, module_name)
  return (not file_readable_3f(backup_path) or (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`")))
end
BackupManager["create-module-backup!"] = function(self, module_name, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local backup_path = self["module-name->new-backup-path"](self, module_name)
  local current_backup_path = self["module-name->current-backup-path"](self, module_name)
  vim.fn.mkdir(vim.fs.dirname(current_backup_path), "p")
  assert(fs.copyfile(path, backup_path))
  return assert(fs.symlink(backup_path, current_backup_path))
end
BackupManager["get-root"] = function()
  return backup_prefix
end
BackupManager["switch-current-backup!"] = function(backup_path)
  _G.assert((nil ~= backup_path), "Missing argument backup-path on fnl/thyme/utils/backup-manager.fnl:85")
  local dir = vim.fs.dirname(backup_path)
  local file_extension = backup_path:match("%..-$")
  local new_current_backup_filename = (".current" .. file_extension)
  local new_current_backup_path = Path.join(dir, new_current_backup_filename)
  return assert(fs.symlink(backup_path, new_current_backup_path))
end
return BackupManager
