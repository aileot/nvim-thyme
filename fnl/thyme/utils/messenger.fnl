(local Messenger {})

(set Messenger.__index Messenger)

(fn Messenger.new [role]
  "Create `Messenger` instance as `role`.
@param role string
@return Messenger"
  (let [self (setmetatable {} Messenger)]
    (set self._role role)
    (set self._prefix (-> "thyme(%s): "
                          (: :format role)))
    self))

(fn Messenger.notify! [self old-msg ...]
  (let [new-msg (.. self._prefix old-msg)]
    (vim.notify new-msg ...)))

(fn Messenger.notify-once! [self old-msg ...]
  (let [new-msg (.. self._prefix old-msg)]
    (vim.notify_once new-msg ...)))

(fn Messenger.warn! [self msg]
  (self:notify! msg vim.log.levels.WARN))

Messenger
