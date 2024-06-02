local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local backup_prefix = Path.join(state_prefix, "rollback")
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
BackupManager["backup-module!"] = function(self, module_name, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  return fs.copyfile(path, self["module-name->backup-path"](self, module_name))
end
return BackupManager
