 local Stack = require("thyme.utils.stack")
 local _local_1_ = require("thyme.utils.general") local validate_type = _local_1_["validate-type"]
 local _local_2_ = require("thyme.utils.fs") local file_readable_3f = _local_2_["file-readable?"] local read_file = _local_2_["read-file"]
 local _local_3_ = require("thyme.module-map.logger") local log_module_map_21 = _local_3_["log-module-map!"]


 local Callstack = Stack.new()

 local cache = {stackframes = {}}

 local function log_21(module_name, fnl_path, lua_path)
 local stackframe = {["module-name"] = module_name, ["fnl-path"] = fnl_path, ["lua-path"] = lua_path}
 cache.stackframes[module_name] = stackframe
 return log_module_map_21(stackframe, Callstack:get()) end

 local function pcall_with_logger_21(callback, fnl_path, _3flua_path, compiler_options, module_name)




 assert(file_readable_3f(fnl_path), ("expected readable file, got " .. fnl_path))

 validate_type("string", module_name)
 local fennel = require("fennel")
 local fnl_code = read_file(fnl_path)
 local stackframe = {["module-name"] = module_name, ["fnl-path"] = fnl_path, ["lua-path"] = _3flua_path} Callstack["push!"](Callstack, stackframe)

 compiler_options["module-name"] = module_name
 compiler_options.filename = fnl_path

 local ok_3f, result = nil, nil local function _4_() return callback(fnl_code, compiler_options, module_name) end ok_3f, result = xpcall(_4_, fennel.traceback) Callstack["pop!"](Callstack)


 if ok_3f then
 log_21(module_name, fnl_path, _3flua_path) else end
 return ok_3f, result end

 local function is_logged_3f(module_name)
 return (nil ~= cache.stackframes[module_name]) end

 local function log_again_21(module_name)
 local _6_ = cache.stackframes[module_name] if (nil ~= _6_) then local stackframe = _6_
 return log_module_map_21(stackframe, Callstack:get()) else local _ = _6_
 return error(("the module " .. module_name .. " is not logged yet.")) end end

 return {["pcall-with-logger!"] = pcall_with_logger_21, ["is-logged?"] = is_logged_3f, ["log-again!"] = log_again_21}
