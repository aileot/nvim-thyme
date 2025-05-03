local RollbackModuleHandler = {}
RollbackModuleHandler.__index = RollbackModuleHandler
RollbackModuleHandler.new = function(module_name)
  local self = setmetatable({}, RollbackModuleHandler)
  self["_module-name"] = module_name
  return self
end
return RollbackModuleHandler
