local _local_1_ = require("thyme.utils.fs")
local read_file = _local_1_["read-file"]
local _local_2_ = require("thyme.utils.iterator")
local gsplit = _local_2_["gsplit"]
local marker = {sep = "\t", macro = "\v", ["end"] = "\n"}
local function modmap__3eline(modmap)
  assert((modmap["module-name"] and modmap["fnl-path"]), ("modmap requires 'module-name' and 'fnl-path'; got module-name: %s, fnl-path: %s"):format(modmap["module-name"], modmap["fnl-path"]))
  return (modmap["module-name"] .. marker.sep .. modmap["fnl-path"] .. marker.sep .. (modmap["lua-path"] or marker.macro) .. marker["end"])
end
local function line__3emodmap(line)
  local inline_dependent_map_pattern = ("^(.-)" .. marker.sep .. "(.-)" .. marker.sep .. "(.*)$")
  local _3_, _4_, _5_ = line:match(inline_dependent_map_pattern)
  if ((nil ~= _3_) and (nil ~= _4_) and (nil ~= _5_)) then
    local module_name = _3_
    local fnl_path = _4_
    local lua_path = _5_
    if (lua_path == marker.macro) then
      return {["module-name"] = module_name, ["fnl-path"] = fnl_path, ["macro?"] = true}
    else
      local _ = lua_path
      return {["module-name"] = module_name, ["fnl-path"] = fnl_path, ["lua-path"] = lua_path}
    end
  else
    local _ = _3_
    return error(("Invalid format: \"%s\""):format(line))
  end
end
local function read_module_map_file(log_path)
  local tbl_16_auto = {}
  for line in gsplit(read_file(log_path):sub(1, -2), marker["end"]) do
    local k_17_auto, v_18_auto = nil, nil
    do
      local _let_8_ = line__3emodmap(line)
      local fnl_path = _let_8_["fnl-path"]
      local modmap = _let_8_
      k_17_auto, v_18_auto = fnl_path, modmap
    end
    if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
      tbl_16_auto[k_17_auto] = v_18_auto
    else
    end
  end
  return tbl_16_auto
end
return {["modmap->line"] = modmap__3eline, ["read-module-map-file"] = read_module_map_file}
