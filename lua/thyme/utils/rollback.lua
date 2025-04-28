local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local assert_is_file_readable = _local_1_["assert-is-file-readable"]
local assert_is_directory = _local_1_["assert-is-directory"]
local read_file = _local_1_["read-file"]
local fs = _local_1_
local _local_2_ = require("thyme.const")
local state_prefix = _local_2_["state-prefix"]
local _local_3_ = require("thyme.utils.pool")
local hide_file_21 = _local_3_["hide-file!"]
local has_hidden_file_3f = _local_3_["has-hidden-file?"]
local restore_file_21 = _local_3_["restore-file!"]
local backup_prefix = Path.join(state_prefix, "rollbacks")
local Rollback = {["_active-backup-filename"] = ".active", ["_pinned-backup-filename"] = ".pinned"}
Rollback.__index = Rollback
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
Rollback.new = function(label, file_extension)
  _G.assert((nil ~= file_extension), "Missing argument file-extension on fnl/thyme/utils/rollback.fnl:38")
  _G.assert((nil ~= label), "Missing argument label on fnl/thyme/utils/rollback.fnl:38")
  local self = setmetatable({}, Rollback)
  local root = Path.join(backup_prefix, label)
  vim.fn.mkdir(root, "p")
  self.root = root
  assert(("." == file_extension:sub(1, 1)), "file-extension must start with `.`")
  self["file-extension"] = file_extension
  return self
end
Rollback["module-name->backup-dir"] = function(self, module_name)
  local dir = Path.join(self.root, module_name)
  return dir
end
Rollback["module-name->new-backup-path"] = function(self, module_name)
  local rollback_id = os.date("%Y-%m-%d_%H-%M-%S")
  local backup_filename = (rollback_id .. self["file-extension"])
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  vim.fn.mkdir(backup_dir, "p")
  return Path.join(backup_dir, backup_filename)
end
Rollback["module-name->active-backup-path"] = function(self, module_name)
  local backup_dir = self["module-name->backup-dir"](self, module_name)
  local active_backup_filename = Rollback["_active-backup-filename"]
  return Path.join(backup_dir, active_backup_filename)
end
Rollback["should-update-backup?"] = function(self, module_name, expected_contents)
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local backup_path = self["module-name->active-backup-path"](self, module_name)
  return (not file_readable_3f(backup_path) or (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`")))
end
Rollback["create-module-backup!"] = function(self, module_name, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local backup_path = self["module-name->new-backup-path"](self, module_name)
  local active_backup_path = self["module-name->active-backup-path"](self, module_name)
  vim.fn.mkdir(vim.fs.dirname(active_backup_path), "p")
  assert(fs.copyfile(path, backup_path))
  return symlink_21(backup_path, active_backup_path)
end
Rollback["get-root"] = function()
  return backup_prefix
end
Rollback["switch-active-backup!"] = function(backup_path)
  _G.assert((nil ~= backup_path), "Missing argument backup-path on fnl/thyme/utils/rollback.fnl:109")
  assert_is_file_readable(backup_path)
  local dir = vim.fs.dirname(backup_path)
  local active_backup_path = Path.join(dir, Rollback["_active-backup-filename"])
  return symlink_21(backup_path, active_backup_path)
end
Rollback["active-backup?"] = function(backup_path)
  assert_is_file_readable(backup_path)
  local dir = vim.fs.dirname(backup_path)
  local active_backup_path = Path.join(dir, Rollback["_active-backup-filename"])
  return (backup_path == fs.readlink(active_backup_path))
end
Rollback["pin-backup!"] = function(backup_dir)
  assert_is_directory(backup_dir)
  local active_backup_path = Path.join(backup_dir, Rollback["_active-backup-filename"])
  local pinned_backup_path = Path.join(backup_dir, Rollback["_pinned-backup-filename"])
  return symlink_21(active_backup_path, pinned_backup_path)
end
Rollback["unpin-backup!"] = function(backup_dir)
  assert_is_directory(backup_dir)
  local pinned_backup_path = Path.join(backup_dir, Rollback["_pinned-backup-prefix"])
  assert_is_file_readable(pinned_backup_path)
  return assert(fs.unlink(pinned_backup_path))
end
return Rollback
