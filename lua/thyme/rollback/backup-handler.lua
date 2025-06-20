local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.util.general")
local validate_type = _local_2_["validate-type"]
local sorter_2ffiles_to_oldest_by_birthtime = _local_2_["sorter/files-to-oldest-by-birthtime"]
local Path = require("thyme.util.path")
local _local_3_ = require("thyme.util.fs")
local file_readable_3f = _local_3_["file-readable?"]
local assert_is_file_readable = _local_3_["assert-is-file-readable"]
local assert_is_symlink = _local_3_["assert-is-symlink"]
local read_file = _local_3_["read-file"]
local fs = _local_3_
local BackupHandler = {}
BackupHandler.__index = BackupHandler
BackupHandler.new = function(root_dir, file_extension, module_name)
  local attrs = {["_latest-cache-linkname"] = ".latest", ["_active-backup-filename"] = ".active", ["_mounted-backup-filename"] = ".mounted"}
  local self = setmetatable(attrs, BackupHandler)
  self["_root-dir"] = root_dir
  self["_file-extension"] = file_extension
  self["_module-name"] = module_name
  return self
end
BackupHandler["determine-backup-dir"] = function(self)
  local dir = Path.join(self["_root-dir"], self["_module-name"])
  return dir
end
BackupHandler["list-backup-files"] = function(self)
  local backup_dir = self["determine-backup-dir"](self)
  return vim.fn.glob(Path.join(backup_dir, "*"), false, true)
end
BackupHandler["suggest-new-backup-path"] = function(self)
  local rollback_id = (os.date("%Y-%m-%d_%H-%M-%S") .. "_" .. vim.uv.hrtime())
  local backup_filename = (rollback_id .. self["_file-extension"])
  local backup_dir = self["determine-backup-dir"](self)
  vim.fn.mkdir(backup_dir, "p")
  return Path.join(backup_dir, backup_filename)
end
BackupHandler["determine-latest-cache-link-path"] = function(self)
  local backup_dir = self["determine-backup-dir"](self)
  local filename = self["_latest-cache-linkname"]
  return Path.join(backup_dir, filename)
end
BackupHandler["update-latest-cache-link!"] = function(self, cache_path)
  local link_path = self["determine-latest-cache-link-path"](self)
  return fs["symlink!"](cache_path, link_path)
end
BackupHandler["clear-latest-cache!"] = function(self)
  local link_path = self["determine-latest-cache-link-path"](self)
  local cache_path = fs.readlink(link_path)
  if ((1 == cache_path:find(lua_cache_prefix, 1, true)) and fs.stat(cache_path)) then
    return assert(fs.unlink(cache_path))
  else
    return nil
  end
end
BackupHandler["determine-active-backup-path"] = function(self)
  local backup_dir = self["determine-backup-dir"](self)
  local filename = self["_active-backup-filename"]
  return Path.join(backup_dir, filename)
end
BackupHandler["determine-active-backup-birthtime"] = function(self)
  local _5_
  do
    local tmp_3_ = self["determine-active-backup-path"](self, self["_module-name"])
    if (nil ~= tmp_3_) then
      local tmp_3_0 = fs.stat(tmp_3_)
      if (nil ~= tmp_3_0) then
        _5_ = tmp_3_0.birthtime.sec
      else
        _5_ = nil
      end
    else
      _5_ = nil
    end
  end
  if (nil ~= _5_) then
    local time = _5_
    return os.date("%c", time)
  else
    return nil
  end
end
BackupHandler["switch-active-backup!"] = function(self, path)
  local dir = self["determine-backup-dir"](self)
  local active_backup_path = self["determine-active-backup-path"](self)
  assert(path:find(dir, 1, true), ("expected path under backup directory %s, got %s"):format(dir, path))
  return fs["symlink!"](path, active_backup_path)
end
BackupHandler["determine-mounted-backup-path"] = function(self)
  local backup_dir = self["determine-backup-dir"](self)
  local filename = self["_mounted-backup-filename"]
  return Path.join(backup_dir, filename)
end
BackupHandler["should-update-backup?"] = function(self, expected_contents)
  local module_name = self["_module-name"]
  assert(not file_readable_3f(module_name), ("expected module-name, got path " .. module_name))
  local backup_path = self["determine-active-backup-path"](self, module_name)
  return (not file_readable_3f(backup_path) or (read_file(backup_path) ~= assert(expected_contents, "expected non empty string for `expected-contents`")))
end
BackupHandler["has-mounted?"] = function(self)
  local mounted_backup_path = self["determine-mounted-backup-path"](self)
  return file_readable_3f(mounted_backup_path)
end
BackupHandler["mount-backup!"] = function(self)
  local active_backup_path = self["determine-active-backup-path"](self)
  local mounted_backup_path = self["determine-mounted-backup-path"](self)
  assert_is_file_readable(active_backup_path)
  fs["symlink!"](active_backup_path, mounted_backup_path)
  return self["clear-latest-cache!"](self)
end
BackupHandler["unmount-backup!"] = function(self)
  local mounted_backup_path = self["determine-mounted-backup-path"](self)
  assert_is_symlink(mounted_backup_path)
  return assert(fs.unlink(mounted_backup_path))
end
BackupHandler["cleanup-old-backups!"] = function(self)
  local Config = require("thyme.config")
  local max_rollbacks = Config["max-rollbacks"]
  validate_type("number", max_rollbacks)
  local threshold = (max_rollbacks + 1)
  local backup_files = self["list-backup-files"](self)
  table.sort(backup_files, sorter_2ffiles_to_oldest_by_birthtime)
  for i = threshold, #backup_files do
    local path = backup_files[i]
    assert(fs.unlink(path))
  end
  return nil
end
BackupHandler["write-backup!"] = function(self, path)
  assert(file_readable_3f(path), ("expected readable file, got " .. path))
  local module_name = self["_module-name"]
  local backup_path = self["suggest-new-backup-path"](self, module_name)
  local active_backup_path = self["determine-active-backup-path"](self, module_name)
  vim.fn.mkdir(vim.fs.dirname(active_backup_path), "p")
  self["update-latest-cache-link!"](self, path)
  assert(fs.copyfile(path, backup_path))
  return fs["symlink!"](backup_path, active_backup_path)
end
return BackupHandler
