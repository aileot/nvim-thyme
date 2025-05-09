local Path = require("thyme.utils.path")
local raw_uv = (vim.uv or vim.loop)
local uv
local function _1_(self, key)
  local call = (raw_uv[key] or raw_uv[("fs_" .. key)])
  self[key] = call
  local function _2_(...)
    return call(...)
  end
  return _2_
end
uv = setmetatable({}, {__index = _1_})
local function file_readable_3f(path)
  return (1 == vim.fn.filereadable(path))
end
local function directory_3f(path)
  return (1 == vim.fn.isdirectory(path))
end
local function assert_is_file_readable(path)
  if not file_readable_3f(path) then
    return error(("not a readable file: " .. path))
  else
    return nil
  end
end
local function assert_is_directory(path)
  if not directory_3f(path) then
    return error(("not a directory: " .. path))
  else
    return nil
  end
end
local function assert_is_full_path(full_path)
  local _5_
  if ("/" == Path.sep) then
    _5_ = ("/" == full_path:sub(1, 1))
  else
    _5_ = (":\\" == full_path:sub(2, 3))
  end
  return assert(_5_, (full_path .. " is not a full path"))
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
  local function close_handlers_12_auto(ok_13_auto, ...)
    file:close()
    if ok_13_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _8_()
    return file:read("*a")
  end
  return close_handlers_12_auto(_G.xpcall(_8_, (package.loaded.fennel or _G.debug or {}).traceback))
end
local function write_file_21(path, contents)
  local f = assert(io.open(path, "w"), ("failed to write to " .. path))
  local function close_handlers_12_auto(ok_13_auto, ...)
    f:close()
    if ok_13_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _10_()
    return f:write(contents)
  end
  return close_handlers_12_auto(_G.xpcall(_10_, (package.loaded.fennel or _G.debug or {}).traceback))
end
local function append_file_21(path, contents)
  local f = assert(io.open(path, "a"), ("failed to append to " .. path))
  local function close_handlers_12_auto(ok_13_auto, ...)
    f:close()
    if ok_13_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _12_()
    return f:write(contents)
  end
  return close_handlers_12_auto(_G.xpcall(_12_, (package.loaded.fennel or _G.debug or {}).traceback))
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
  local function _13_(err, fd)
    assert(not err, err)
    local function _14_(err0)
      assert(not err0, err0)
      local function _15_(err1)
        return assert(not err1, err1)
      end
      return uv.fs_close(fd, _15_)
    end
    return uv.fs_write(fd, text, _14_)
  end
  return uv.fs_open(path, flags, rw_, _13_)
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
  local _let_16_ = require("thyme.utils.pool")
  local hide_file_21 = _let_16_["hide-file!"]
  local has_hidden_file_3f = _let_16_["has-hidden-file?"]
  local restore_file_21 = _let_16_["restore-file!"]
  if file_readable_3f(new_path) then
    hide_file_21(new_path)
  else
  end
  local _18_, _19_ = nil, nil
  local function _20_()
    return vim.uv.fs_symlink(path, new_path)
  end
  _18_, _19_ = pcall(assert(_20_))
  if ((_18_ == false) and (nil ~= _19_)) then
    local msg = _19_
    if has_hidden_file_3f(new_path) then
      return true
    else
      restore_file_21(new_path)
      vim.notify(msg, vim.log.levels.ERROR)
      return false
    end
  else
    local _ = _18_
    return true
  end
end
local function _23_(_, key)
  return uv[key]
end
return setmetatable({["file-readable?"] = file_readable_3f, ["directory?"] = directory_3f, ["assert-is-file-readable"] = assert_is_file_readable, ["assert-is-directory"] = assert_is_directory, ["assert-is-fnl-file"] = assert_is_fnl_file, ["assert-is-lua-file"] = assert_is_lua_file, ["assert-is-log-file"] = assert_is_log_file, ["read-file"] = read_file, ["write-log-file!"] = write_log_file_21, ["append-log-file!"] = append_log_file_21, ["async-write-log-file!"] = async_write_log_file_21, ["async-append-log-file!"] = async_append_log_file_21, ["delete-file!"] = delete_file_21, ["write-fnl-file!"] = write_fnl_file_21, ["write-lua-file!"] = write_lua_file_21, ["delete-lua-file!"] = delete_lua_file_21, ["delete-log-file!"] = delete_log_file_21, uv = uv}, {__index = _23_})
