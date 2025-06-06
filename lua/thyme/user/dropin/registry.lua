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
  _G.assert((nil ~= replacement), "Missing argument replacement on fnl/thyme/user/dropin/registry.fnl:22")
  _G.assert((nil ~= pattern), "Missing argument pattern on fnl/thyme/user/dropin/registry.fnl:22")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin/registry.fnl:22")
  local unit = {pattern = pattern, replacement = replacement}
  return table.insert(self._registry, unit)
end
Registry.iter = function(self)
  local i = 0
  local function _2_()
    local _3_
    local _4_
    do
      i = (i + 1)
      _4_ = i
    end
    _3_ = self._registry[_4_]
    if (nil ~= _3_) then
      local val = _3_
      return i, val
    else
      return nil
    end
  end
  return _2_
end
return Registry
