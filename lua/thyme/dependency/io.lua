local _local_1_ = require("thyme.util.fs")
local read_file = _local_1_["read-file"]
local assert_is_log_file = _local_1_["assert-is-log-file"]
local _local_2_ = require("thyme.util.iterator")
local gsplit = _local_2_["gsplit"]
local marker = {sep = "\9", macro = "\v", ["end"] = "\n"}
local function modmap__3eline(modmap)
  assert((modmap["module-name"] and modmap["fnl-path"]), ("modmap requires 'module-name' and 'fnl-path'; got module-name: %s, fnl-path: %s"):format(modmap["module-name"], modmap["fnl-path"]))
  return ((modmap["lua-path"] or marker.macro) .. marker.sep .. modmap["module-name"] .. marker.sep .. modmap["fnl-path"] .. marker["end"])
end
local function line__3emodmap(line)
  local inline_dependent_map_pattern = ("^(.-)" .. marker.sep .. "(.-)" .. marker.sep .. "(.*)$")
  local _3_, _4_, _5_ = line:match(inline_dependent_map_pattern)
  if ((_3_ == marker.macro) and (nil ~= _4_) and (nil ~= _5_)) then
    local module_name = _4_
    local fnl_path = _5_
    return {["macro?"] = true, ["module-name"] = module_name, ["fnl-path"] = fnl_path}
  elseif ((nil ~= _3_) and (nil ~= _4_) and (nil ~= _5_)) then
    local lua_path = _3_
    local module_name = _4_
    local fnl_path = _5_
    return {["lua-path"] = lua_path, ["module-name"] = module_name, ["fnl-path"] = fnl_path}
  else
    local _ = _3_
    return error(("Invalid format: \"%s\""):format(line))
  end
end
local function read_module_map_file(log_path)
  local tbl_16_ = {}
  for line in gsplit(read_file(log_path):sub(1, -2), marker["end"]) do
    local k_17_, v_18_ = nil, nil
    do
      local _let_7_ = line__3emodmap(line)
      local fnl_path = _let_7_["fnl-path"]
      local modmap = _let_7_
      k_17_, v_18_ = fnl_path, modmap
    end
    if ((k_17_ ~= nil) and (v_18_ ~= nil)) then
      tbl_16_[k_17_] = v_18_
    else
    end
  end
  return tbl_16_
end
local function macro_recorded_3f(log_path)
  assert_is_log_file(log_path)
  local file = assert(io.open(log_path, "r"), ("failed to read " .. log_path))
  local function close_handlers_12_(ok_13_, ...)
    file:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _10_()
    return (nil ~= file:read("*l"):find(marker.macro, 1, true))
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
local function peek_module_name(log_path)
  assert_is_log_file(log_path)
  local file = assert(io.open(log_path, "r"), ("failed to read " .. log_path))
  local function close_handlers_12_(ok_13_, ...)
    file:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _19_()
    return line__3emodmap(file:read("*l"))["module-name"]
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
local function peek_fnl_path(log_path)
  assert_is_log_file(log_path)
  local file = assert(io.open(log_path, "r"), ("failed to read " .. log_path))
  local function close_handlers_12_(ok_13_, ...)
    file:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _28_()
    return line__3emodmap(file:read("*l"))["fnl-path"]
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
return {["modmap->line"] = modmap__3eline, ["read-module-map-file"] = read_module_map_file, ["macro-recorded?"] = macro_recorded_3f, ["peek-module-name"] = peek_module_name, ["peek-fnl-path"] = peek_fnl_path}
