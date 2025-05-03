(local RollbackModuleHandler {})

(set RollbackModuleHandler.__index RollbackModuleHandler)

(fn RollbackModuleHandler.new [module-name]
  (let [self (setmetatable {} RollbackModuleHandler)]
    (set self._module-name module-name)
    self))

RollbackModuleHandler
