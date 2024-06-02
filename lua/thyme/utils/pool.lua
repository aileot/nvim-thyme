 local _local_1_ = require("thyme.const") local state_prefix = _local_1_["state-prefix"]

 local Path = require("thyme.utils.path")
 local fs = require("thyme.utils.fs")

 local _local_2_ = require("thyme.utils.uri") local uri_encode = _local_2_["uri-encode"]
 local _local_3_ = require("thyme.utils.iterator") local each_file = _local_3_["each-file"]

 local pool_prefix = Path.join(state_prefix, "pool")

 vim.fn.mkdir(pool_prefix, "p")

 local function path__3epool_path(path)
 return Path.join(pool_prefix, uri_encode(path)) end

 local function hide_file_21(path)
 return fs.rename(path, path__3epool_path(path)) end

 local function restore_file_21(path)
 return fs.rename(path__3epool_path(path), path) end

 local function copy_file_21(path)
 return fs.copyfile(path, path__3epool_path(path)) end

 local function hide_dir_21(dir_path)
 return each_file(hide_file_21, dir_path) end

 return {["hide-file!"] = hide_file_21, ["restore-file!"] = restore_file_21, ["copy-file!"] = copy_file_21, ["hide-dir!"] = hide_dir_21}
