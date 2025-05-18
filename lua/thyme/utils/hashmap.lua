local HashMap = {}
HashMap.__index = HashMap
HashMap.new = function(_3ftbl)
  local self = setmetatable({}, HashMap)
  assert(((nil == _3ftbl) or ("table" == type(_3ftbl))), "Expected `nil` or a table, got ", type(_3ftbl))
  self._map = (_3ftbl or {})
  return self
end
HashMap["insert!"] = function(self, key, value)
  self._map[key] = value
  return nil
end
HashMap["or-insert!"] = function(self, key, value)
  if (nil == self:get(key)) then
    self._map[key] = value
    return nil
  else
    return nil
  end
end
HashMap.get = function(self, key)
  _G.assert((nil ~= key), "Missing argument key on fnl/thyme/utils/hashmap.fnl:27")
  _G.assert((nil ~= self), "Missing argument self on fnl/thyme/utils/hashmap.fnl:27")
  return self._map[key]
end
HashMap["contains?"] = function(self, key)
  if self:get(key) then
    return true
  else
    return false
  end
end
HashMap.keys = function(self)
  local tbl_21_ = {}
  local i_22_ = 0
  for key in pairs(self._map) do
    local val_23_ = key
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  return tbl_21_
end
HashMap.values = function(self)
  local tbl_21_ = {}
  local i_22_ = 0
  for _key, val in pairs(self._map) do
    local val_23_ = val
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  return tbl_21_
end
HashMap["clear!"] = function(self)
  self["_hidden-map"] = self._map
  self._map = {}
  return nil
end
HashMap["restore!"] = function(self)
  assert(self["_hidden-map"], "The map is not cleared.")
  self._map = self["_hidden-map"]
  self["_hidden-map"] = nil
  return nil
end
return HashMap
