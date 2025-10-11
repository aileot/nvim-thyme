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
    local case_8_ = vim.api.nvim_get_runtime_file("fennel.lua", false)
    if ((_G.type(case_8_) == "table") and (nil ~= case_8_[1])) then
      local fennel_lua_path = case_8_[1]
      _9_ = fennel_lua_path
    elseif ((_G.type(case_8_) == "table") and (case_8_[1] == nil)) then
      _9_ = false
    else
      _9_ = nil
    end
  end
  local or_13_ = _9_
  if not or_13_ then
    local rtp = vim.api.nvim_get_option_value("rtp", {})
    local case_15_ = (rtp:match(Path.join("([^,]+", "fennel),")) or rtp:match(Path.join("([^,]+", "fennel)$")))
    if (nil ~= case_15_) then
      local fennel_repo_path = case_15_
      or_13_ = compile_fennel_into_rtp_21(fennel_repo_path)
    else
      local _ = case_15_
      or_13_ = error("No `fennel.lua`, no `fennel`, and no Fennel repo found.\nPlease make sure to add the path to fennel repo in `&runtimepath`, or install a `fennel` executable.")
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
  local case_22_, case_23_ = loadfile(cached_fennel_path)
  if ((case_22_ == false) and (nil ~= case_23_)) then
    local err_msg = case_23_
    local msg = LoaderMessenger["mk-failure-reason"](LoaderMessenger, ("Failed to load fennel.lua.\nError Message:\n%s\nContents:\n%s"):format(err_msg, read_file(cached_fennel_path)))
    fs.unlink(cached_fennel_path)
    return msg
  elseif (nil ~= case_22_) then
    local lua_chunk = case_22_
    return lua_chunk
  else
    return nil
  end
end
return {["locate-fennel-path!"] = locate_fennel_path_21, ["load-fennel"] = load_fennel}
