local _local_1_ = require("thyme.util.general")
local starts_with_3f = _local_1_["starts-with?"]
local Path = require("thyme.util.path")
local raw_uv = (vim.uv or vim.loop)
local uv
local function _2_(self, key)
  local call = (raw_uv[key] or raw_uv[("fs_" .. key)])
  self[key] = call
  local function _3_(...)
    return call(...)
  end
  return _3_
end
uv = setmetatable({}, {__index = _2_})
local function executable_3f(cmd)
  return (1 == vim.fn.executable(cmd))
end
local function file_readable_3f(path)
  return (("string" == type(path)) and (1 == vim.fn.filereadable(path)))
end
local function directory_3f(path)
  return (("string" == type(path)) and (1 == vim.fn.isdirectory(path)))
end
local function under_tmpdir_3f(path)
  local tmp_dir = (os.getenv("TMPDIR") or os.getenv("TEMP") or os.getenv("TMP") or "/tmp")
  return starts_with_3f(path, tmp_dir)
end
local function assert_is_file_readable(path)
  if not file_readable_3f(path) then
    return error(("not a readable file, got %s as type %s"):format(vim.inspect(path), type(path)))
  else
    return nil
  end
end
local function assert_is_directory(path)
  if not directory_3f(path) then
    return error(("not a directory, got %s as type %s"):format(vim.inspect(path), type(path)))
  else
    return nil
  end
end
local function assert_is_full_path(full_path)
  local _6_
  if ("/" == Path.sep) then
    _6_ = ("/" == full_path:sub(1, 1))
  else
    _6_ = (":\\" == full_path:sub(2, 3))
  end
  return assert(_6_, (full_path .. " is not a full path"))
end
local function assert_is_symlink(path)
  if not ("link" == vim.fn.getftype(path)) then
    return error(("expected a symbolic link; got %s as type %s"):format(path, vim.fn.getftype(path)))
  else
    return nil
  end
end
local function assert_file_extension(path, extension)
  assert(("." == extension:sub(1, 1)), "`extension` must start with `.`")
  return assert((extension == path:sub(( - #extension))), (path .. " does not end with " .. extension))
end
local function assert_is_fnl_file(fnl_path)
  assert_is_full_path(fnl_path)
  return assert_file_extension(fnl_path, ".fnl")
end
local function assert_is_lua_file(lua_path)
  assert_is_full_path(lua_path)
  return assert_file_extension(lua_path, ".lua")
end
local function assert_is_log_file(log_path)
  assert_is_full_path(log_path)
  return assert_file_extension(log_path, ".log")
end
local function read_file(path)
  local file = assert(io.open(path, "r"), ("failed to read " .. path))
  local function close_handlers_12_(ok_13_, ...)
    file:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _10_()
    return file:read("*a")
  end
  local _12_
  do
    local t_11_ = _G
    if (nil ~= t_11_) then
      t_11_ = t_11_.package
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_.loaded
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_.fennel
    else
    end
    _12_ = t_11_
  end
  local or_16_ = _12_ or _G.debug
  if not or_16_ then
    local function _17_()
      return ""
    end
    or_16_ = {traceback = _17_}
  end
  return close_handlers_12_(_G.xpcall(_10_, or_16_.traceback))
end
local function write_file_21(path, contents)
  local f = assert(io.open(path, "w"), ("failed to write to " .. path))
  local function close_handlers_12_(ok_13_, ...)
    f:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _19_()
    return f:write(contents)
  end
  local _21_
  do
    local t_20_ = _G
    if (nil ~= t_20_) then
      t_20_ = t_20_.package
    else
    end
    if (nil ~= t_20_) then
      t_20_ = t_20_.loaded
    else
    end
    if (nil ~= t_20_) then
      t_20_ = t_20_.fennel
    else
    end
    _21_ = t_20_
  end
  local or_25_ = _21_ or _G.debug
  if not or_25_ then
    local function _26_()
      return ""
    end
    or_25_ = {traceback = _26_}
  end
  return close_handlers_12_(_G.xpcall(_19_, or_25_.traceback))
end
local function append_file_21(path, contents)
  local f = assert(io.open(path, "a"), ("failed to append to " .. path))
  local function close_handlers_12_(ok_13_, ...)
    f:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _28_()
    return f:write(contents)
  end
  local _30_
  do
    local t_29_ = _G
    if (nil ~= t_29_) then
      t_29_ = t_29_.package
    else
    end
    if (nil ~= t_29_) then
      t_29_ = t_29_.loaded
    else
    end
    if (nil ~= t_29_) then
      t_29_ = t_29_.fennel
    else
    end
    _30_ = t_29_
  end
  local or_34_ = _30_ or _G.debug
  if not or_34_ then
    local function _35_()
      return ""
    end
    or_34_ = {traceback = _35_}
  end
  return close_handlers_12_(_G.xpcall(_28_, or_34_.traceback))
end
local function delete_file_21(path)
  return uv.fs_unlink(path)
end
local function write_fnl_file_21(fnl_path, fnl_lines)
  assert_is_fnl_file(fnl_path)
  vim.fn.mkdir(vim.fs.dirname(fnl_path), "p")
  return write_file_21(fnl_path, fnl_lines)
end
local function write_lua_file_21(lua_path, lua_lines)
  assert_is_lua_file(lua_path)
  vim.fn.mkdir(vim.fs.dirname(lua_path), "p")
  return write_file_21(lua_path, lua_lines)
end
local function delete_lua_file_21(lua_path)
  assert_is_lua_file(lua_path)
  return delete_file_21(lua_path)
end
local function delete_log_file_21(log_path)
  assert_is_log_file(log_path)
  return delete_file_21(log_path)
end
local function write_log_file_21(log_path, log_lines)
  assert_is_log_file(log_path)
  vim.fn.mkdir(vim.fs.dirname(log_path), "p")
  return write_file_21(log_path, log_lines)
end
local function append_log_file_21(log_path, log_lines)
  assert_is_log_file(log_path)
  return append_file_21(log_path, log_lines)
end
local function async_write_file_with_flags_21(path, text, flags)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local rw_ = 438
  local function _36_(err, fd)
    assert(not err, err)
    local function _37_(err0)
      assert(not err0, err0)
      local function _38_(err1)
        return assert(not err1, err1)
      end
      return uv.fs_close(fd, _38_)
    end
    return uv.fs_write(fd, text, _37_)
  end
  return uv.fs_open(path, flags, rw_, _36_)
end
local function async_write_log_file_21(log_path, lines)
  assert_is_log_file(log_path)
  return async_write_file_with_flags_21(log_path, lines, "w")
end
local function async_append_log_file_21(log_path, lines)
  assert_is_log_file(log_path)
  return async_write_file_with_flags_21(log_path, lines, "a")
end
uv["symlink!"] = function(path, new_path, ...)
  local _let_39_ = require("thyme.util.pool")
  local hide_file_21 = _let_39_["hide-file!"]
  local has_hidden_file_3f = _let_39_["has-hidden-file?"]
  local restore_file_21 = _let_39_["restore-file!"]
  if file_readable_3f(new_path) then
    hide_file_21(new_path)
  else
  end
  local _41_, _42_ = nil, nil
  local function _43_()
    return vim.uv.fs_symlink(path, new_path)
  end
  _41_, _42_ = pcall(assert(_43_))
  if ((_41_ == false) and (nil ~= _42_)) then
    local msg = _42_
    if has_hidden_file_3f(new_path) then
      return true
    else
      restore_file_21(new_path)
      vim.notify(msg, vim.log.levels.ERROR)
      return false
    end
  else
    local _ = _41_
    return true
  end
end
local function _46_(_, key)
  return uv[key]
end
return setmetatable({["executable?"] = executable_3f, ["file-readable?"] = file_readable_3f, ["directory?"] = directory_3f, ["under-tmpdir?"] = under_tmpdir_3f, ["assert-is-file-readable"] = assert_is_file_readable, ["assert-is-directory"] = assert_is_directory, ["assert-is-symlink"] = assert_is_symlink, ["assert-is-fnl-file"] = assert_is_fnl_file, ["assert-is-lua-file"] = assert_is_lua_file, ["assert-is-log-file"] = assert_is_log_file, ["read-file"] = read_file, ["write-log-file!"] = write_log_file_21, ["append-log-file!"] = append_log_file_21, ["async-write-log-file!"] = async_write_log_file_21, ["async-append-log-file!"] = async_append_log_file_21, ["delete-file!"] = delete_file_21, ["write-fnl-file!"] = write_fnl_file_21, ["write-lua-file!"] = write_lua_file_21, ["delete-lua-file!"] = delete_lua_file_21, ["delete-log-file!"] = delete_log_file_21, uv = uv}, {__index = _46_})
