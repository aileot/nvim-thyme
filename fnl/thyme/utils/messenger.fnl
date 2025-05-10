(local Messenger {:notified {}})

(set Messenger.__index Messenger)

(fn Messenger.new [scope]
  "Create `Messenger` instance as `scope`.
@param scope string
@return Messenger"
  (assert (not (scope:find "^thyme")) ;
          (.. "`scope` must not starts with `thyme`: " scope))
  (assert (not (scope:find "^%[thyme")) ;
          (.. "`scope` must not starts with `[thyme`: " scope))
  (let [self (setmetatable {} Messenger)]
    (set self._role scope)
    (set self._prefix (-> "thyme(%s): "
                          (: :format scope)))
    self))

(fn Messenger.wrap-msg [self old-msg]
  "Wrap message with `scope` signature.
@param scope string
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
  (let [Config (require :thyme.config) ;
        ;; NOTE: Avoid "loop or previous error".
        new-msg (self:wrap-msg old-msg)]
    (Config.notifier new-msg ...)))

(fn Messenger.notify-once! [self old-msg ...]
  ;; REF: $VIMRUNTIME/lua/vim/_editor.lua
  (or (. self.notified old-msg) ;
      (do
        (self:notify! old-msg ...)
        (tset self.notified old-msg true)
        true)))

Messenger
