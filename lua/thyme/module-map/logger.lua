

 local Path = require("thyme.utils.path")
 local ModuleMap = require("thyme.module-map.unit")

 local _local_1_ = require("thyme.utils.fs") local delete_log_file_21 = _local_1_["delete-log-file!"]
 local _local_2_ = require("thyme.const") local state_prefix = _local_2_["state-prefix"]

 local modmap_prefix = Path.join(state_prefix, "modmap")

 vim.fn.mkdir(modmap_prefix, "p")




 local module_maps

 local function _3_(self, fnl_path)
 local modmap = ModuleMap.new(fnl_path)
 do end (self)[fnl_path] = modmap
 return modmap end module_maps = setmetatable({}, {__index = _3_})

 local function log_module_map_21(dependency, dependent_stack)




 local module_map
 local function _4_() local modmap, logged_3f = ModuleMap.new(dependency["fnl-path"])
 if not logged_3f then modmap["set-module-map!"](modmap, dependency) else end

 module_maps[dependency["fnl-path"]] = modmap
 return modmap end module_map = (rawget(module_maps, dependency["fnl-path"]) or _4_())
 local _6_ = dependent_stack[#dependent_stack] if (nil ~= _6_) then local dependent = _6_
 if not module_map["get-dependent-map"](module_map, dependent["fnl-path"]) then return module_map["add-dependent"](module_map, dependent) else return nil end else return nil end end


 local function fnl_path__3eentry_map(fnl_path)





 return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(module_maps[fnl_path], "get-entry-map") end


 local function fnl_path__3edependent_map(fnl_path)





 return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(module_maps[fnl_path], "get-dependent-map") end


 local function fnl_path__3elua_path(fnl_path)



 local _9_ = fnl_path__3eentry_map(fnl_path) if (nil ~= _9_) then local modmap = _9_
 return modmap["lua-path"] else return nil end end





 local function clear_module_map_21(fnl_path)


 local modmap = module_maps[fnl_path] return modmap["clear!"](modmap) end


 local function restore_module_map_21(fnl_path)


 local modmap = module_maps[fnl_path] return modmap["restore!"](modmap) end


 local function clear_dependency_log_files_21()

 local modmap_dir = modmap_prefix
 for log_file, _ in vim.fs.dir(modmap_dir) do
 local path = Path.join(modmap_dir, log_file)
 delete_log_file_21(path) end return nil end

 return {["log-module-map!"] = log_module_map_21, ["fnl-path->entry-map"] = fnl_path__3eentry_map, ["fnl-path->dependent-map"] = fnl_path__3edependent_map, ["fnl-path->lua-path"] = fnl_path__3elua_path, ["clear-module-map!"] = clear_module_map_21, ["restore-module-map!"] = restore_module_map_21, ["clear-dependency-log-files!"] = clear_dependency_log_files_21}
