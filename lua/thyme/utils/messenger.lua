local Messenger = {}
Messenger.__index = Messenger
Messenger.new = function(role)
  local self = setmetatable({}, Messenger)
  self._role = role
  self._prefix = ("thyme(%s): "):format(role)
  return self
end
Messenger["notify!"] = function(self, old_msg, ...)
  local new_msg = (self._prefix .. old_msg)
  return vim.notify(new_msg, ...)
end
Messenger["notify-once!"] = function(self, old_msg, ...)
  local new_msg = (self._prefix .. old_msg)
  return vim.notify_once(new_msg, ...)
end
Messenger["warn!"] = function(self, msg)
  return self["notify!"](self, msg, vim.log.levels.WARN)
end
return Messenger
