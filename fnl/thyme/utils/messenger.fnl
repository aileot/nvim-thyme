(local Messenger {:notified {}})

(set Messenger.__index Messenger)

(fn Messenger.new [role]
  "Create `Messenger` instance as `role`.
@param role string
@return Messenger"
  (assert (not (role:find "^thyme")) ;
          (.. "`role` must not starts with `thyme`: " role))
  (assert (not (role:find "^%[thyme")) ;
          (.. "`role` must not starts with `[thyme`: " role))
  (let [self (setmetatable {} Messenger)]
    (set self._role role)
    (set self._prefix (-> "thyme(%s): "
                          (: :format role)))
    self))

(fn Messenger.wrap-msg [self old-msg]
  "Wrap message with `role` signature.
@param role string
@return Messenger"
  (.. self._prefix old-msg))

(fn Messenger._validate-raw-msg! [raw-msg]
  (assert (not (raw-msg:find "^thyme"))
          "The raw message must not starts with `thyme`")
  (assert (not (raw-msg:find "^%[thyme"))
          "The raw message must not starts with `[thyme`")
  (assert (raw-msg:find "^[a-z]")
          "The raw message must not starts with a lowercase letter"))

(fn Messenger.notify! [self old-msg ...]
  (self._validate-raw-msg! old-msg)
  (let [new-msg (self:wrap-msg old-msg)]
    (vim.notify new-msg ...)))

(fn Messenger.notify-once! [self old-msg ...]
  ;; REF: $VIMRUNTIME/lua/vim/_editor.lua
  (or (. self.notified old-msg) ;
      (do
        (self:notify! old-msg ...)
        (tset self.notified old-msg true)
        true)))

Messenger
