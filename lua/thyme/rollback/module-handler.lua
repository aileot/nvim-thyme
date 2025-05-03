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
RollbackModuleHandler.new = function(module_name)
  local self = setmetatable({}, RollbackModuleHandler)
  self["_module-name"] = module_name
  return self
end
RollbackModuleHandler["module-name->backup-dir"] = function(self, module_name)
  local dir = Path.join(self["_kind-dir"], module_name)
  return dir
end
RollbackModuleHandler["module-name->backup-files"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  return vim.fn.glob(Path.join(backup_dir, "*"), false, true)
end
RollbackModuleHandler["module-name->new-backup-path"] = function(self, module_name)
  local rollback_id = (os.date("%Y-%m-%d_%H-%M-%S") .. "_" .. vim.uv.hrtime())
  local backup_filename = (rollback_id .. self["file-extension"])
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  vim.fn.mkdir(backup_dir, "p")
  return Path.join(backup_dir, backup_filename)
end
RollbackModuleHandler["module-name->active-backup-path"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  local filename = RollbackModuleHandler["_active-backup-filename"]
  return Path.join(backup_dir, filename)
end
RollbackModuleHandler["module-name->active-backup-birthtime"] = function(self, module_name)
  local _9_
  do
    local tmp_3_auto = self["module-name->active-backup-path"](self, module_name)
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
RollbackModuleHandler["module-name->mounted-backup-path"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  local filename = RollbackModuleHandler["_mounted-backup-filename"]
  return Path.join(backup_dir, filename)
end
RollbackModuleHandler["should-update-backup?"] = function(self, module_name, expected_contents)
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local backup_path = self["module-name->active-backup-path"](self, module_name)
  return (not file_readable_3f(backup_path) or (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`")))
end
RollbackModuleHandler["create-module-backup!"] = function(self, module_name, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local backup_path = self["module-name->new-backup-path"](self, module_name)
  local active_backup_path = self["module-name->active-backup-path"](self, module_name)
  vim.fn.mkdir(vim.fs.dirname(active_backup_path), "p")
  assert(fs.copyfile(path, backup_path))
  return symlink_21(backup_path, active_backup_path)
end
RollbackModuleHandler["search-module-from-mounted-backups"] = function(self, module_name)
  local rollback_path = self["module-name->mounted-backup-path"](self, module_name)
  local loader_name = ("thyme-mounted-rollback-%s-loader"):format(self._kind)
  if file_readable_3f(rollback_path) then
    local resolved_path = fs.readlink(rollback_path)
    local msg = ("%s: rollback to mounted backup for %s %s (created at %s)"):format(loader_name, self._kind, module_name, module_name, self["module-name->active-backup-birthtime"](self, module_name))
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
return RollbackModuleHandler
