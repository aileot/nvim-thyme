(local Stack (require :thyme.util.class.stack))
(local {: validate-type} (require :thyme.util.general))
(local {: assert-is-file-readable : read-file} (require :thyme.util.fs))

(local Stackframe (require :thyme.dependency.stackframe))
(local DependencyLogger (require :thyme.dependency.logger))

(local Config (require :thyme.config))

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
  (assert-is-file-readable fnl-path)
  (validate-type :string module-name)
  (let [fennel (require :fennel)
        raw-fnl-code (read-file fnl-path)
        ;; The same params as fennel.compile-string or fennel.eval.
        new-fnl-code (Config.preproc raw-fnl-code
                                     {:source raw-fnl-code
                                      :module-name module-name
                                      :filename fnl-path
                                      :env compiler-options.env})
        stackframe (Stackframe.new {: module-name
                                    : fnl-path
                                    :lua-path ?lua-path})]
    (self.callstack:push! stackframe)
    (set compiler-options.module-name module-name)
    (set compiler-options.filename fnl-path)
    ;; NOTE: callback only expects fennel.compile-string or fennel.eval.
    (let [(ok? result) (xpcall #(callback new-fnl-code compiler-options
                                          module-name)
                               fennel.traceback)]
      (self.callstack:pop!)
      (when ok?
        (tset self.module-name->stackframe module-name stackframe)
        ;; NOTE: It must NOT refresh dependency map for macro; only ThymeWatch
        ;; should refresh dependency map log.
        (DependencyLogger:log-module-map! stackframe (self.callstack:get)))
      (values ok? result))))

(fn Observer.observed? [self module-name]
  (not= nil (. self.module-name->stackframe module-name)))

(fn Observer.log-dependent! [self module-name]
  (case (. self.module-name->stackframe module-name)
    stackframe (DependencyLogger:log-module-map! stackframe
                                                 (self.callstack:get))
    _ (error (.. "the module " module-name " is not logged yet."))))

(local SingletonObserver (Observer._new))

SingletonObserver
