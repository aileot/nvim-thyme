local Registry = {}
Registry.__index = Registry
Registry.new = function()
  local self = setmetatable({}, Registry)
  self._registry = {}
  return self
end
Registry["clear!"] = function(self)
  self.__registry = self._registry
  self._registry = {}
  return nil
end
Registry["resume!"] = function(self)
  if self.__registry then
    self._registry = self.__registry
    self.__registry = nil
    return nil
  else
    return nil
  end
end
Registry["register!"] = function(self, pattern, replacement)
  if (nil == replacement) then
    _G.error("Missing argument replacement on fnl/thyme/user/dropin/registry.fnl:22", 2)
  else
  end
  if (nil == pattern) then
    _G.error("Missing argument pattern on fnl/thyme/user/dropin/registry.fnl:22", 2)
  else
  end
  if (nil == self) then
    _G.error("Missing argument self on fnl/thyme/user/dropin/registry.fnl:22", 2)
  else
  end
  local unit = {pattern = pattern, replacement = replacement}
  return table.insert(self._registry, unit)
end
Registry.iter = function(self)
  local i = 0
  local function _5_()
    local case_6_
    local _7_
    do
      i = (i + 1)
      _7_ = i
    end
    case_6_ = self._registry[_7_]
    if (nil ~= case_6_) then
      local val = case_6_
      return i, val
    else
      return nil
    end
  end
  return _5_
end
return Registry
