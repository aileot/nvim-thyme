local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local Path = require("thyme.util.path")
local _local_2_ = require("thyme.util.fs")
local executable_3f = _local_2_["executable?"]
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local read_file = _local_2_["read-file"]
local fs = _local_2_
local _local_3_ = require("thyme.util.pool")
local can_restore_file_3f = _local_3_["can-restore-file?"]
local restore_file_21 = _local_3_["restore-file!"]
local Messenger = require("thyme.util.class.messenger")
local LoaderMessenger = Messenger.new("loader/fennel")
local function compile_fennel_into_rtp_21(fennel_repo_path)
  local fennel_lua_file = "fennel.lua"
  local _let_4_ = vim.fs.find("Makefile", {upward = true, path = fennel_repo_path})
  local fennel_src_Makefile = _let_4_[1]
  local _ = assert(fennel_src_Makefile, "Could not find Makefile for fennel.lua.")
  local fennel_src_root = vim.fs.dirname(fennel_src_Makefile)
  local _3flua
  if executable_3f("luajit") then
    _3flua = "luajit"
  elseif executable_3f("lua") then
    local stdout = vim.system({"lua", "-v"}, {text = true}):wait().stdout
    if (stdout:find("^LuaJIT") or stdout:find("^Lua 5%.1%.")) then
      _3flua = "lua"
    else
      _3flua = nil
    end
  else
    _3flua = nil
  end
  local LUA = (_3flua or "nvim --clean --headless -l")
  local env = {LUA = LUA}
  local on_exit
  local function _7_(out)
    return assert((0 == tonumber(out.code)), ("failed to compile fennel.lua with code: %s\n%s"):format(out.code, out.stderr))
  end
  on_exit = _7_
  local make_cmd = {"make", "-C", fennel_src_root, fennel_lua_file}
  local fennel_lua_path = Path.join(fennel_src_root, fennel_lua_file)
  vim.system(make_cmd, {text = true, env = env}, on_exit):wait()
  return fennel_lua_path
end
local function locate_fennel_path_21()
  local _9_
  do
    local _8_ = vim.api.nvim_get_runtime_file("fennel.lua", false)
    if ((_G.type(_8_) == "table") and (nil ~= _8_[1])) then
      local fennel_lua_path = _8_[1]
      _9_ = fennel_lua_path
    elseif ((_G.type(_8_) == "table") and (_8_[1] == nil)) then
      _9_ = false
    else
      _9_ = nil
    end
  end
  local or_13_ = _9_
  if not or_13_ then
    local _14_ = vim.api.nvim_get_runtime_file("fennel", false)
    if ((_G.type(_14_) == "table") and (nil ~= _14_[1])) then
      local fennel_lua_path = _14_[1]
      or_13_ = fennel_lua_path
    elseif ((_G.type(_14_) == "table") and (_14_[1] == nil)) then
      or_13_ = false
    else
      or_13_ = nil
    end
  end
  if not or_13_ then
    local rtp = vim.api.nvim_get_option_value("rtp", {})
    local _20_ = (rtp:match(Path.join("([^,]+", "fennel),")) or rtp:match(Path.join("([^,]+", "fennel)$")))
    if (nil ~= _20_) then
      local fennel_repo_path = _20_
      or_13_ = compile_fennel_into_rtp_21(fennel_repo_path)
    else
      local _ = _20_
      if executable_3f("fennel") then
        or_13_ = vim.fn.exepath("fennel")
      else
        or_13_ = error("No `fennel.lua`, no `fennel`, no Fennel repo, and no `fennel` executable found.\nPlease make sure to add the path to fennel repo in `&runtimepath`, or install a `fennel` executable.")
      end
    end
  end
  return or_13_
end
local function cache_fennel_lua_21(fennel_lua_path)
  assert_is_file_readable(fennel_lua_path)
  local fennel_lua_file = "fennel.lua"
  local cached_fennel_path = Path.join(lua_cache_prefix, fennel_lua_file)
  if not (cached_fennel_path == fennel_lua_path) then
    vim.fn.mkdir(vim.fs.dirname(cached_fennel_path), "p")
    if can_restore_file_3f(cached_fennel_path, read_file(fennel_lua_path)) then
      restore_file_21(cached_fennel_path)
    else
      fs.copyfile(fennel_lua_path, cached_fennel_path)
    end
    assert_is_file_readable(cached_fennel_path)
  else
  end
  return cached_fennel_path
end
local function load_fennel(fennel_lua_path)
  local cached_fennel_path = cache_fennel_lua_21(fennel_lua_path)
  local _28_, _29_ = loadfile(cached_fennel_path)
  if ((_28_ == false) and (nil ~= _29_)) then
    local err_msg = _29_
    local msg = LoaderMessenger["mk-failure-reason"](LoaderMessenger, ("Failed to load fennel.lua.\nError Message:\n%s\nContents:\n%s"):format(err_msg, read_file(cached_fennel_path)))
    fs.unlink(cached_fennel_path)
    return msg
  elseif (nil ~= _28_) then
    local lua_chunk = _28_
    return lua_chunk
  else
    return nil
  end
end
return {["locate-fennel-path!"] = locate_fennel_path_21, ["load-fennel"] = load_fennel}
