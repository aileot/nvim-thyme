(local Stack {})

(set Stack.__index Stack)

(fn Stack.new []
  (let [self (setmetatable {:_stack []} Stack)]
    self))

(fn Stack.push! [self item]
  "Push `item` to the `stack` instance.
@param item table"
  (table.insert self._stack item))

(fn Stack.pop! [self]
  "Remove the last item of the `stack` instance.
@return any the popped item"
  (table.remove self._stack))

(fn Stack.get [self]
  self._stack)

Stack
