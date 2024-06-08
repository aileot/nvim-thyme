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
BackupManager.new = function(label)
  local self = setmetatable({}, BackupManager)
  local root = Path.join(backup_prefix, label)
  vim.fn.mkdir(root, "p")
  self.root = root
  return self
end
BackupManager["module-name->backup-path"] = function(self, module_name)
  return Path.join(self.root, module_name)
end
BackupManager["should-backup-module?"] = function(self, module_name, expected_contents)
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local backup_path = self["module-name->backup-path"](self, module_name)
  return (not file_readable_3f(backup_path) or (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`")))
end
BackupManager["backup-module!"] = function(self, module_name, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local backup_path = self["module-name->backup-path"](self, module_name)
  return assert(fs.copyfile(path, backup_path))
end
BackupManager["get-root"] = function()
  return backup_prefix
end
return BackupManager
