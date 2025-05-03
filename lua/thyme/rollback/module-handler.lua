local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local fs = _local_1_
local _local_2_ = require("thyme.utils.pool")
local hide_file_21 = _local_2_["hide-file!"]
local has_hidden_file_3f = _local_2_["has-hidden-file?"]
local restore_file_21 = _local_2_["restore-file!"]
local RollbackModuleHandler = {}
RollbackModuleHandler.__index = RollbackModuleHandler
local function symlink_21(path, new_path, ...)
  if file_readable_3f(new_path) then
    hide_file_21(new_path)
  else
  end
  local _4_, _5_ = nil, nil
  local function _6_()
    return vim.uv.fs_symlink(path, new_path)
  end
  _4_, _5_ = pcall(assert(_6_))
  if ((_4_ == false) and (nil ~= _5_)) then
    local msg = _5_
    if has_hidden_file_3f(new_path) then
      return true
    else
      restore_file_21(new_path)
      vim.notify(msg, vim.log.levels.ERROR)
      return false
    end
  else
    local _ = _4_
    return true
  end
end
RollbackModuleHandler.new = function(root_dir, file_extension, module_name)
  local attrs = {["_active-backup-filename"] = ".active", ["_mounted-backup-filename"] = ".mounted"}
  local self = setmetatable(attrs, RollbackModuleHandler)
  self["_root-dir"] = root_dir
  self["_file-extension"] = file_extension
  self["_module-name"] = module_name
  return self
end
RollbackModuleHandler["module-name->backup-dir"] = function(self)
  local dir = Path.join(self["_root-dir"], self["_module-name"])
  return dir
end
RollbackModuleHandler["module-name->backup-files"] = function(self)
  local backup_dir = self["module-name->backup-dir"](self, self["_module-name"])
  return vim.fn.glob(Path.join(backup_dir, "*"), false, true)
end
RollbackModuleHandler["module-name->new-backup-path"] = function(self)
  local rollback_id = (os.date("%Y-%m-%d_%H-%M-%S") .. "_" .. vim.uv.hrtime())
  local backup_filename = (rollback_id .. self["_file-extension"])
  local backup_dir = self["module-name->backup-dir"](self, self["_module-name"])
  vim.fn.mkdir(backup_dir, "p")
  return Path.join(backup_dir, backup_filename)
end
RollbackModuleHandler["module-name->active-backup-path"] = function(self)
  local backup_dir = self["module-name->backup-dir"](self, self["_module-name"])
  local filename = RollbackModuleHandler["_active-backup-filename"]
  return Path.join(backup_dir, filename)
end
RollbackModuleHandler["module-name->active-backup-birthtime"] = function(self)
  local _9_
  do
    local tmp_3_auto = self["module-name->active-backup-path"](self, self["_module-name"])
    if (nil ~= tmp_3_auto) then
      local tmp_3_auto0 = fs.stat(tmp_3_auto)
      if (nil ~= tmp_3_auto0) then
        _9_ = tmp_3_auto0.birthtime.sec
      else
        _9_ = nil
      end
    else
      _9_ = nil
    end
  end
  if (nil ~= _9_) then
    local time = _9_
    return os.date("%c", time)
  else
    return nil
  end
end
RollbackModuleHandler["module-name->mounted-backup-path"] = function(self)
  local backup_dir = self["module-name->backup-dir"](self, self["_module-name"])
  local filename = RollbackModuleHandler["_mounted-backup-filename"]
  return Path.join(backup_dir, filename)
end
RollbackModuleHandler["should-update-backup?"] = function(self, expected_contents)
  local module_name = self["_module-name"]
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local backup_path = self["module-name->active-backup-path"](self, module_name)
  return (not file_readable_3f(backup_path) or (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`")))
end
RollbackModuleHandler["create-module-backup!"] = function(self, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local module_name = self["_module-name"]
  local backup_path = self["module-name->new-backup-path"](self, module_name)
  local active_backup_path = self["module-name->active-backup-path"](self, module_name)
  vim.fn.mkdir(vim.fs.dirname(active_backup_path), "p")
  assert(fs.copyfile(path, backup_path))
  return symlink_21(backup_path, active_backup_path)
end
return RollbackModuleHandler
