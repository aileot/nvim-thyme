local HashMap = {}
HashMap.__index = HashMap
HashMap.new = function(_3ftbl)
  local self = setmetatable({}, HashMap)
  assert(((nil == _3ftbl) or ("table" == type(_3ftbl))), "Expected `nil` or a table, got ", type(_3ftbl))
  self._hash_map = (_3ftbl or {})
  return self
end
HashMap["insert!"] = function(self, key, value)
  self._hash_map[key] = value
  return nil
end
HashMap["or-insert!"] = function(self, key, value)
  if (nil == self:get(key)) then
    self._hash_map[key] = value
    return nil
  else
    return nil
  end
end
HashMap.get = function(self, key)
  if (nil == key) then
    _G.error("Missing argument key on fnl/thyme/util/class/hashmap.fnl:27", 2)
  else
  end
  if (nil == self) then
    _G.error("Missing argument self on fnl/thyme/util/class/hashmap.fnl:27", 2)
  else
  end
  return self._hash_map[key]
end
HashMap["contains?"] = function(self, key)
  if self:get(key) then
    return true
  else
    return false
  end
end
HashMap.keys = function(self)
  local tbl_26_ = {}
  local i_27_ = 0
  for key in pairs(self._hash_map) do
    local val_28_ = key
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
HashMap.values = function(self)
  local tbl_26_ = {}
  local i_27_ = 0
  for _key, val in pairs(self._hash_map) do
    local val_28_ = val
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
HashMap["hide!"] = function(self)
  self["_hidden-map"] = self._hash_map
  self._hash_map = {}
  return nil
end
HashMap["restore!"] = function(self)
  assert(self["_hidden-map"], "The map is not cleared.")
  self._hash_map = self["_hidden-map"]
  self["_hidden-map"] = nil
  return nil
end
return HashMap
