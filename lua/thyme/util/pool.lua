local _local_1_ = require("thyme.const")
local state_prefix = _local_1_["state-prefix"]
local Path = require("thyme.util.path")
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local read_file = _local_2_["read-file"]
local fs = _local_2_
local _local_3_ = require("thyme.util.uri")
local uri_encode = _local_3_["uri-encode"]
local _local_4_ = require("thyme.util.iterator")
local each_file = _local_4_["each-file"]
local pool_prefix = Path.join(state_prefix, "pool")
vim.fn.mkdir(pool_prefix, "p")
local function path__3epool_path(path)
  return Path.join(pool_prefix, uri_encode(path))
end
local function hide_file_21(path)
  assert_is_file_readable(path)
  local pool_path = path__3epool_path(path)
  vim.fn.mkdir(vim.fs.dirname(pool_path), "p")
  return assert(fs.rename(path, pool_path))
end
local function restore_file_21(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  return assert(fs.rename(path__3epool_path(path), path))
end
local function hide_files_in_dir_21(dir_path)
  return each_file(hide_file_21, dir_path)
end
local function has_hidden_file_3f(path)
  local pool_path = path__3epool_path(path)
  return file_readable_3f(pool_path)
end
local function can_restore_file_3f(path, expected_contents)
  local pool_path = path__3epool_path(path)
  return (file_readable_3f(pool_path) and (read_file(pool_path) == assert(expected_contents, "expected non empty string for `expected-contents`")))
end
local function get_root()
  return pool_prefix
end
return {["hide-file!"] = hide_file_21, ["restore-file!"] = restore_file_21, ["hide-files-in-dir!"] = hide_files_in_dir_21, ["has-hidden-file?"] = has_hidden_file_3f, ["can-restore-file?"] = can_restore_file_3f, ["get-root"] = get_root}
