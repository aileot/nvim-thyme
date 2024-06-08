(local Stack (require :thyme.utils.stack))
(local {: validate-type} (require :thyme.utils.general))
(local {: file-readable? : read-file} (require :thyme.utils.fs))
(local {: log-module-map!} (require :thyme.module-map.logger))

;; Note: The Callstack instance is shared by all the modmap instances.
(local Callstack (Stack.new))

(local cache {:stackframes {}})

(fn log! [module-name fnl-path lua-path]
  (let [stackframe {: module-name : fnl-path : lua-path}]
    (tset cache.stackframes module-name stackframe)
    (log-module-map! stackframe (Callstack:get))))

(fn pcall-with-logger! [callback
                        fnl-path
                        ?lua-path
                        compiler-options
                        module-name]
  (assert (file-readable? fnl-path)
          (.. "expected readable file, got " fnl-path))
  (validate-type :string module-name)
  (let [fennel (require :fennel)
        fnl-code (read-file fnl-path)
        stackframe {: module-name : fnl-path :lua-path ?lua-path}]
    (Callstack:push! stackframe)
    (set compiler-options.module-name module-name)
    (set compiler-options.filename fnl-path)
    ;; Note: callback only expects fennel.compile-string or fennel.eval.
    (let [(ok? result) (xpcall #(callback fnl-code compiler-options module-name)
                               fennel.traceback)]
      (Callstack:pop!)
      (when ok?
        (log! module-name fnl-path ?lua-path))
      (values ok? result))))

(fn is-logged? [module-name]
  (not= nil (. cache.stackframes module-name)))

(fn log-again! [module-name]
  (case (. cache.stackframes module-name)
    stackframe (log-module-map! stackframe (Callstack:get))
    _ (error (.. "the module " module-name " is not logged yet."))))

{: pcall-with-logger! : is-logged? : log-again!}
