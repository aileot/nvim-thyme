local function _1_(_self, key)
  return require("thyme.config")[key]
end
return setmetatable({}, {__index = _1_})
