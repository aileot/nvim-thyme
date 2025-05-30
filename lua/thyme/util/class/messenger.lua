local Messenger = {notified = {}}
Messenger.__index = Messenger
Messenger.new = function(scope)
  assert(not scope:find("^thyme"), ("`scope` must not starts with `thyme`: " .. scope))
  assert(not scope:find("^%[thyme"), ("`scope` must not starts with `[thyme`: " .. scope))
  assert(not scope:find("[%^%(%)%%%.%*%+%-%?]"), ("`scope` cannot contain any magic character like `.` and `-`: " .. scope))
  local self = setmetatable({}, Messenger)
  self._role = scope
  self._prefix = ("thyme(%s): "):format(scope)
  return self
end
Messenger["wrap-msg"] = function(self, old_msg)
  return (self._prefix .. old_msg)
end
Messenger["mk-failure-reason"] = function(self, old_msg, ...)
  return ("\n" .. self["wrap-msg"](self, old_msg))
end
Messenger["_validate-raw-msg!"] = function(raw_msg)
  assert(not raw_msg:find("^thyme"), "The raw message must not starts with `thyme`")
  return assert(not raw_msg:find("^%[thyme"), "The raw message must not starts with `[thyme`")
end
Messenger["notify!"] = function(self, old_msg, ...)
  self["_validate-raw-msg!"](old_msg)
  local Config = require("thyme.config")
  local new_msg = self["wrap-msg"](self, old_msg)
  return Config.notifier(new_msg, ...)
end
Messenger["notify-once!"] = function(self, old_msg, ...)
  local or_1_ = self.notified[old_msg]
  if not or_1_ then
    self["notify!"](self, old_msg, ...)
    self.notified[old_msg] = true
    or_1_ = true
  end
  return or_1_
end
return Messenger
