(import-macros {: when-not} :thyme.macros)

(local fennel (require :fennel))

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

(fn recompile! [fnl-path lua-path]
  "Recompile `fnl-path` to `lua-path`.
@param fnl-path string
@param lua-path string"
  (let [config (get-main-config)
        compiler-options config.compiler-options
        {: module-name} (fnl-path->entry-map fnl-path)]
    ;; Note: With "module-name" option, macro-searcher can map macro
    ;; dependency.
    ;; TODO: Clear lua cache if necessary.
    (set compiler-options.module-name module-name)
    ;; Note: module-map must be cleared before logging, but after getting
    ;; its maps.
    (clear-module-map! fnl-path)
    (case (pcall-with-logger! fennel.compile-string fnl-path lua-path
                              compiler-options module-name)
      (true lua-code)
      ;; Note: The lua-code update-check has already been done above.
      (write-lua-file-with-backup! lua-path lua-code module-name)
      (_ error-msg)
      (let [msg (: "thyme-recompiler: abort recompiling %s due to the following error
%s" :format fnl-path error-msg)]
        (vim.notify msg vim.log.levels.WARN)
        (restore-module-map! fnl-path)))))

(lambda update-module-dependencies! [fnl-path ?lua-path-to-clear opts]
  "Clear cache files of `fnl-path` and its dependent files.
@param fnl-path string
@param ?lua-path-to-compile string
@param opts table"
  ;; Note: module names only matter on &rtp to reload.
  (case (fnl-path->dependent-map fnl-path)
    dependent-map (each [dependent-fnl-path dependent (pairs dependent-map)]
                    (update-module-dependencies! dependent-fnl-path
                                                 dependent.lua-path opts)))
  (let [should-recompile-lua-cache? ;
        (and ?lua-path-to-clear
             (or (not (file-readable? ?lua-path-to-clear))
                 (not= (read-file ?lua-path-to-clear) ;
                       (compile-file fnl-path))))]
    (when should-recompile-lua-cache?
      (recompile! fnl-path))))

(fn check-to-update! [fnl-path ?opts]
  (let [opts (or ?opts {})
        lua-path (fnl-path->lua-path fnl-path)]
    ;; TODO: Add option to live-reload.
    (update-module-dependencies! fnl-path lua-path opts)))

{: check-to-update!}
