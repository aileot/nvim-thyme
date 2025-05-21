(local {: assert-is-file-readable} (require :thyme.util.fs))

(local Stackframe {})
(set Stackframe.__index Stackframe)

(fn Stackframe.get-module-name [self]
  self.module-name)

(fn Stackframe.get-fnl-path [self]
  self.fnl-path)

(fn Stackframe.get-lua-path [self]
  self.lua-path)

(fn Stackframe.new [{: module-name : fnl-path : lua-path}]
  "Create a new instance of `Stackframe` with `module-name`, `fnl-path`,
and optional `lua-path` info.
@param module-name string
@param fnl-path string
@param lua-path string|nil
@return Stackframe"
  (let [self (setmetatable {} Stackframe)]
    (set self.module-name module-name)
    (assert-is-file-readable fnl-path)
    (set self.fnl-path (vim.fn.resolve fnl-path))
    (set self.lua-path lua-path)
    self))

(fn Stackframe.validate-stackframe! [val]
  "Validate that given value is a `Stackframe`.
@param val any"
  (assert (= :table (type val)) (.. "expected a table; got " (type val)))
  (assert (next val) "expected a non-empty table")
  (assert-is-file-readable val.fnl-path)
  (assert (= :string (type val.module-name)) "`module-name` must be a string"))

Stackframe
