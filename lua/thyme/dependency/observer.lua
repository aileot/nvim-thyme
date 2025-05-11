local Stack = require("thyme.utils.stack")
local _local_1_ = require("thyme.utils.general")
local validate_type = _local_1_["validate-type"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local read_file = _local_2_["read-file"]
local _local_3_ = require("thyme.dependency.logger")
local log_module_map_21 = _local_3_["log-module-map!"]
local Observer = {}
Observer.__index = Observer
Observer._new = function()
  local self = setmetatable({}, Observer)
  self.callstack = Stack.new()
  self["module-name->stackframe"] = {}
  return self
end
Observer["observe!"] = function(self, callback, fnl_path, _3flua_path, compiler_options, module_name)
  assert(file_readable_3f(fnl_path), ("expected readable file, got " .. fnl_path))
  validate_type("string", module_name)
  local fennel = require("fennel")
  local fnl_code = read_file(fnl_path)
  local stackframe = {["module-name"] = module_name, ["fnl-path"] = fnl_path, ["lua-path"] = _3flua_path}
  self.callstack["push!"](self.callstack, stackframe)
  compiler_options["module-name"] = module_name
  compiler_options.filename = fnl_path
  local ok_3f, result = nil, nil
  local function _4_()
    return callback(fnl_code, compiler_options, module_name)
  end
  ok_3f, result = xpcall(_4_, fennel.traceback)
  self.callstack["pop!"](self.callstack)
  if ok_3f then
    self["module-name->stackframe"][module_name] = stackframe
    log_module_map_21(stackframe, self.callstack:get())
  else
  end
  return ok_3f, result
end
Observer["observed?"] = function(self, module_name)
  return (nil ~= self["module-name->stackframe"][module_name])
end
Observer["log-depedent!"] = function(self, module_name)
  local _6_ = self["module-name->stackframe"][module_name]
  if (nil ~= _6_) then
    local stackframe = _6_
    return log_module_map_21(stackframe, self.callstack:get())
  else
    local _ = _6_
    return error(("the module " .. module_name .. " is not logged yet."))
  end
end
local SingletonObserver = Observer._new()
return SingletonObserver
