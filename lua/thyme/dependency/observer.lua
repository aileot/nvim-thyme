local Stack = require("thyme.utils.stack")
local _local_1_ = require("thyme.utils.general")
local validate_type = _local_1_["validate-type"]
local _local_2_ = require("thyme.utils.fs")
local assert_is_file_readable = _local_2_["assert-is-file-readable"]
local read_file = _local_2_["read-file"]
local Stackframe = require("thyme.dependency.stackframe")
local DependencyLogger = require("thyme.dependency.logger")
local Observer = {}
Observer.__index = Observer
Observer._new = function()
  local self = setmetatable({}, Observer)
  self.callstack = Stack.new()
  self["module-name->stackframe"] = {}
  return self
end
Observer["observe!"] = function(self, callback, fnl_path, _3flua_path, compiler_options, module_name)
  assert_is_file_readable(fnl_path)
  validate_type("string", module_name)
  local fennel = require("fennel")
  local fnl_code = read_file(fnl_path)
  local stackframe = Stackframe.new({["module-name"] = module_name, ["fnl-path"] = fnl_path, ["lua-path"] = _3flua_path})
  self.callstack["push!"](self.callstack, stackframe)
  compiler_options["module-name"] = module_name
  compiler_options.filename = fnl_path
  local ok_3f, result = nil, nil
  local function _3_()
    return callback(fnl_code, compiler_options, module_name)
  end
  ok_3f, result = xpcall(_3_, fennel.traceback)
  self.callstack["pop!"](self.callstack)
  if ok_3f then
    self["module-name->stackframe"][module_name] = stackframe
    DependencyLogger["log-module-map!"](DependencyLogger, stackframe, self.callstack:get())
  else
  end
  return ok_3f, result
end
Observer["observed?"] = function(self, module_name)
  return (nil ~= self["module-name->stackframe"][module_name])
end
Observer["log-dependent!"] = function(self, module_name)
  local _5_ = self["module-name->stackframe"][module_name]
  if (nil ~= _5_) then
    local stackframe = _5_
    return DependencyLogger["log-module-map!"](DependencyLogger, stackframe, self.callstack:get())
  else
    local _ = _5_
    return error(("the module " .. module_name .. " is not logged yet."))
  end
end
local SingletonObserver = Observer._new()
return SingletonObserver
