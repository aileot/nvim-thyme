(local Stack (require :thyme.utils.stack))
(local {: validate-type} (require :thyme.utils.general))
(local {: file-readable? : read-file} (require :thyme.utils.fs))
(local {: log-module-map!} (require :thyme.dependency.logger))

(local Observer {})

(set Observer.__index Observer)

(fn Observer._new []
  (let [self (setmetatable {} Observer)]
    (set self.callstack (Stack.new))
    (set self.module-name->stackframe {})
    self))

(fn Observer.observe! [self
                       callback
                       fnl-path
                       ?lua-path
                       compiler-options
                       module-name]
  "Apply `pcall` to `callback` logging dependency `module-map` with the current
callstacks.
@param callback function
@param fnl-path string
@param ?lua-path string
@param compiler-options table
@param module-name string
@return boolean the result of `pcall` to `callback`
@return false|any false if `callback` failed; otherwise, return `callback` results"
  (assert (file-readable? fnl-path)
          (.. "expected readable file, got " fnl-path))
  (validate-type :string module-name)
  (let [fennel (require :fennel)
        fnl-code (read-file fnl-path)
        stackframe {: module-name : fnl-path :lua-path ?lua-path}]
    (self.callstack:push! stackframe)
    (set compiler-options.module-name module-name)
    (set compiler-options.filename fnl-path)
    ;; NOTE: callback only expects fennel.compile-string or fennel.eval.
    (let [(ok? result) (xpcall #(callback fnl-code compiler-options module-name)
                               fennel.traceback)]
      (self.callstack:pop!)
      (when ok?
        (tset self.module-name->stackframe module-name stackframe)
        (log-module-map! stackframe (self.callstack:get)))
      (values ok? result))))

(fn Observer.is-logged? [self module-name]
  (not= nil (. self.module-name->stackframe module-name)))

(fn Observer.log-depedent! [self module-name]
  (case (. self.module-name->stackframe module-name)
    stackframe (log-module-map! stackframe (self.callstack:get))
    _ (error (.. "the module " module-name " is not logged yet."))))

(local SingletonObserver (Observer._new))

SingletonObserver
