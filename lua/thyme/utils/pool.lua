local _local_1_ = require("thyme.const")
local state_prefix = _local_1_["state-prefix"]
local Path = require("thyme.utils.path")
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local read_file = _local_2_["read-file"]
local fs = _local_2_
local _local_3_ = require("thyme.utils.uri")
local uri_encode = _local_3_["uri-encode"]
local _local_4_ = require("thyme.utils.iterator")
local each_file = _local_4_["each-file"]
local pool_prefix = Path.join(state_prefix, "pool")
vim.fn.mkdir(pool_prefix, "p")
local function path__3epool_path(path)
  return Path.join(pool_prefix, uri_encode(path))
end
local function hide_file_21(path)
  return assert(fs.rename(path, path__3epool_path(path)))
end
local function restore_file_21(path)
  return assert(fs.rename(path__3epool_path(path), path))
end
local function hide_files_in_dir_21(dir_path)
  return each_file(hide_file_21, dir_path)
end
local function can_restore_file_3f(path, expected_contents)
  local pool_path = path__3epool_path(path)
  return (file_readable_3f(pool_path) and (read_file(pool_path) == assert(expected_contents, "expected non empty string for `expected-contents`")))
end
return {["hide-file!"] = hide_file_21, ["restore-file!"] = restore_file_21, ["hide-files-in-dir!"] = hide_files_in_dir_21, ["can-restore-file?"] = can_restore_file_3f}
