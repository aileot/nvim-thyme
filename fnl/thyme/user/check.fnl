(import-macros {: when-not} :thyme.macros)

(local fennel (require :fennel))

(local {: do-nothing} (require :thyme.utils.general))
(local {: file-readable? : read-file} (require :thyme.utils.fs))

(local {: get-main-config} (require :thyme.config))
(local {: compile-file} (require :thyme.wrapper.fennel))
(local {: pcall-with-logger!} (require :thyme.module-map.callstack))
(local {: fnl-path->lua-path
        : fnl-path->entry-map
        : fnl-path->dependent-map
        : clear-module-map!
        : restore-module-map!} (require :thyme.module-map.logger))

(local {: write-lua-file-with-backup!} (require :thyme.searcher.module))

(local default-strategy :recompile)

(fn fnl-path->dependent-count [fnl-path]
  (case (fnl-path->dependent-map fnl-path)
    dependent-map (accumulate [i 0 _ _ (pairs dependent-map)]
                    i)
    _ 0))

(fn should-recompile-lua-cache? [fnl-path ?lua-path]
  (and ?lua-path (or (not (file-readable? ?lua-path))
                     (not= (read-file ?lua-path) ;
                           (compile-file fnl-path)))))

(fn recompile! [fnl-path lua-path module-name]
  "Recompile `fnl-path` to `lua-path`.
@param fnl-path string
@param lua-path string
@return boolean return `true` if successfully recompile `fnl-path`; otherwise, return `false`."
  (let [config (get-main-config)
        compiler-options config.compiler-options]
    ;; Note: With "module-name" option, macro-searcher can map macro
    ;; dependency.
    ;; TODO: Clear lua cache if necessary.
    (set compiler-options.module-name module-name)
    ;; Note: module-map must be cleared before logging, but after getting
    ;; its maps.
    (clear-module-map! fnl-path)
    (case (pcall-with-logger! fennel.compile-string fnl-path lua-path
                              compiler-options module-name)
      (true lua-code) (do
                        (write-lua-file-with-backup! lua-path lua-code
                                                     module-name)
                        true)
      (_ error-msg)
      (let [msg (: "thyme-recompiler: abort recompiling %s due to the following error
  %s" :format fnl-path error-msg)]
        (vim.notify msg vim.log.levels.WARN)
        (restore-module-map! fnl-path)
        false))))

(lambda update-module-dependencies! [fnl-path ?lua-path opts]
  "Clear cache files of `fnl-path` and its dependent files.
@param fnl-path string
@param ?lua-path-to-compile string
@param opts table"
  (let [strategy (or opts._strategy (error "no strategy is specified"))
        {: module-name} (fnl-path->entry-map fnl-path)
        notifiers (or opts.notifier {})]
    (when ?lua-path
      (case strategy
        ;; TODO: Activate the strategies:
        ;; - clear-all
        ;; - clear
        ;; - recompile
        ;; - reload
        ;; - and `always-` prefixed option each
        :always-recompile
        (let [ok? (recompile! fnl-path ?lua-path module-name)]
          (when (and ok? notifiers.recompile)
            (notifiers.recompile (.. "[thyme] successfully recompile " fnl-path))))
        :recompile
        (when (should-recompile-lua-cache? fnl-path ?lua-path)
          (let [ok? (recompile! fnl-path ?lua-path module-name)]
            (when (and ok? notifiers.recompile)
              (notifiers.recompile (.. "[thyme] successfully recompile "
                                       fnl-path)))))))
    (case strategy
      (where (or :recompile :reload :always-recompile :always-reload))
      (case (fnl-path->dependent-map fnl-path)
        dependent-map (each [dependent-fnl-path dependent (pairs dependent-map)]
                        (update-module-dependencies! dependent-fnl-path
                                                     dependent.lua-path opts)))
      _ (error (.. "unsupported strategy: " strategy)))))

(fn check-to-update! [fnl-path ?opts]
  "Check if the compiled lua files mapped to `fnl-path` should be updated.
How to update is to be determined by `strategy` option.
@param fnl-path string
@param ?opts table
@param ?opts.strategy nil|string|fun(dependent-count: number, context: table): string the `context` only provides `module-name` at present."
  (let [opts (or ?opts {})
        lua-path (fnl-path->lua-path fnl-path)]
    (case (fnl-path->entry-map fnl-path)
      modmap (let [dependent-count (fnl-path->dependent-count fnl-path)
                   strategy (case (type opts.strategy)
                              :string opts.strategy
                              :function (let [context {:module-name modmap.module-name}]
                                          (opts.strategy dependent-count
                                                         context))
                              :nil default-strategy
                              else (error (.. "expected string or function, got "
                                              else)))]
               (set opts._strategy strategy)
               (update-module-dependencies! fnl-path lua-path opts)
               (set opts._strategy nil)))))

{: check-to-update!}
