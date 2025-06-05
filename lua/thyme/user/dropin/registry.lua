local Registry = {}
Registry.__index = Registry
Registry.new = function()
  local self = setmetatable({}, Registry)
  self._registry = {}
  return self
end
Registry["clear!"] = function(self)
  self._registry = {}
  return nil
end
Registry["register!"] = function(self, pattern, replacement)
  _G.assert((nil ~= replacement), "Missing argument replacement on fnl/thyme/user/dropin/registry.fnl:15")
  _G.assert((nil ~= pattern), "Missing argument pattern on fnl/thyme/user/dropin/registry.fnl:15")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/user/dropin/registry.fnl:15")
  local unit = {pattern = pattern, replacement = replacement}
  return table.insert(self._registry, unit)
end
Registry.iter = function(self)
  local i = 0
  local function _1_()
    local _2_
    local _3_
    do
      i = (i + 1)
      _3_ = i
    end
    _2_ = self._registry[_3_]
    if (nil ~= _2_) then
      local val = _2_
      return i, val
    else
      return nil
    end
  end
  return _1_
end
return Registry
