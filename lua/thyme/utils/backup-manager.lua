local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local directory_3f = _local_1_["directory?"]
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local backup_prefix = Path.join(state_prefix, "backup")
local BackupManager = {}
BackupManager.__index = BackupManager
BackupManager.new = function(label)
  local self = setmetatable({}, BackupManager)
  local root = Path.join(backup_prefix, label)
  vim.fn.mkdir(root, "p")
  self.root = root
  return self
end
BackupManager["module-name->backup-dir"] = function(self, module_name)
  local dir = Path.join(self.root, module_name)
  return dir
end
BackupManager["module-name->new-backup-path"] = function(self, module_name)
  local rollback_id = os.date("%Y-%m-%d_%H-%M-%S")
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  vim.fn.mkdir(backup_dir, "p")
  return Path.join(backup_dir, rollback_id)
end
BackupManager["module-name->?current-backup-path"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  if directory_3f(backup_dir) then
    local files = vim.fn.readdir(backup_dir)
    local rollback_id = files[#files]
    local backup_path = Path.join(backup_dir, rollback_id)
    if file_readable_3f(backup_path) then
      return backup_path
    else
      return nil
    end
  else
    return nil
  end
end
BackupManager["should-update-backup?"] = function(self, module_name, expected_contents)
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local _5_ = self["module-name->?current-backup-path"](self, module_name)
  if (_5_ == nil) then
    return true
  elseif (nil ~= _5_) then
    local backup_path = _5_
    return (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`"))
  else
    return nil
  end
end
BackupManager["create-module-backup!"] = function(self, module_name, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local backup_path = self["module-name->new-backup-path"](self, module_name)
  vim.fn.mkdir(vim.fs.dirname(backup_path), "p")
  return assert(fs.copyfile(path, backup_path))
end
BackupManager["get-root"] = function()
  return backup_prefix
end
return BackupManager
