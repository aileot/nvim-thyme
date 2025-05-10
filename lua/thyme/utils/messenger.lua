local Messenger = {}
Messenger.__index = Messenger
Messenger.new = function(role)
  assert(not role:find("^thyme"), ("`role` must not starts with `thyme`: " .. role))
  assert(not role:find("^%[thyme"), ("`role` must not starts with `[thyme`: " .. role))
  local self = setmetatable({}, Messenger)
  self._role = role
  self._prefix = ("thyme(%s): "):format(role)
  return self
end
Messenger["wrap-msg"] = function(self, old_msg)
  return (self._prefix .. old_msg)
end
Messenger["_validate-raw-msg!"] = function(raw_msg)
  assert(not raw_msg:find("^thyme"), "The raw message must not starts with `thyme`")
  assert(not raw_msg:find("^%[thyme"), "The raw message must not starts with `[thyme`")
  return assert(raw_msg:find("^[a-z]"), "The raw message must not starts with a lowercase letter")
end
Messenger["notify!"] = function(self, old_msg, ...)
  self["_validate-raw-msg!"](old_msg)
  local new_msg = self["wrap-msg"](self, old_msg)
  return vim.notify(new_msg, ...)
end
Messenger["notify-once!"] = function(self, old_msg, ...)
  self["_validate-raw-msg!"](old_msg)
  local new_msg = self["wrap-msg"](self, old_msg)
  return vim.notify_once(new_msg, ...)
end
return Messenger
