(local fennel (require :fennel))

(local {: lua-cache-prefix : config-path} (require :thyme.const))

(local {: get-config} (require :thyme.config))
(local {: each-file} (require :thyme.utils.iterator))
(local {:get-root get-root-of-backup} (require :thyme.rollback))
(local {:get-root get-root-of-pool} (require :thyme.utils.pool))
(local {: get-runtime-files} (require :thyme.wrapper.nvim))
(local {: macro-recorded? : peek-module-name : peek-fnl-path}
       (require :thyme.module-map.format))

(local {:get-root get-root-of-modmap} (require :thyme.module-map.unit))

(local RollbackManager (require :thyme.rollback))

(local (report-start report-info report-ok report-warn report-error)
       (let [health vim.health]
         (if health.start
             (values health.start health.info health.ok health.warn
                     health.error)
             ;; For nvim <0.10.0
             ;; (The support will be dropped w/o deprecation notice.)
             (values health.report_start health.report_info health.report_ok
                     health.report_warn health.report_error))))

(fn report-integrations []
  (report-start "Thyme Integrations")
  (let [reporter (if (= nil vim.g.parinfer_loaded)
                     report-warn
                     report-ok)]
    (reporter (-> "`%s`"
                  (: :format
                     (.. "vim.g.parinfer_loaded = "
                         (tostring vim.g.parinfer_loaded))))))
  (let [dependency-files [:parser/fennel.so]]
    ;; NOTE: The files "parser-info/*.revision" should only belong to
    ;; https://github.com/nvim-treesitter/nvim-treesitter.
    (each [_ file (ipairs dependency-files)]
      (case (get-runtime-files [file] false)
        [path] (report-ok (: "`%s` is detected at `%s`." :format file path))
        _ (report-warn (: "missing `%s`." :format file))))))

(fn report-thyme-disk-info []
  (report-start "Thyme Disk Info")
  (report-info (-> "The path to .nvim-thyme.fnl: `%s`" (: :format config-path)))
  (report-info (-> "The root path of Lua cache:  `%s`"
                   (: :format lua-cache-prefix)))
  (report-info (-> "The root path of backups for rollback: `%s`"
                   (: :format (get-root-of-backup))))
  (report-info (-> "The root path of module-mapping: `%s`"
                   (: :format (get-root-of-modmap))))
  (report-info (-> "The root path of pool: `%s`"
                   (: :format (get-root-of-pool)))))

(fn report-thyme-config []
  (report-start "Thyme .nvim-thyme.fnl")
  (let [config (get-config)]
    (set config.compiler-options.source nil)
    (set config.compiler-options.module-name nil)
    (set config.compiler-options.filename nil)
    (when config.command.compiler-options
      (set config.command.compiler-options.source nil)
      (set config.command.compiler-options.module-name nil)
      (set config.command.compiler-options.filename nil))
    ;; TODO: Dump the file contents in .nvim-thyme.fnl instead?
    ;; NOTE: To inject fennel syntax, `<` must be put at the head of the line,
    ;; but health does not allow it.
    (report-info (-> "The current config:

%s
"
                     (: :format (fennel.view config))))))

(fn report-fennel-paths []
  (report-start "Thyme fennel.{path,macro-path}")
  (report-info (-> "fennel.path:\n- `%s`" ;
                   (: :format (fennel.path:gsub ";" "`\n- `"))))
  (report-info (-> "fennel.macro-path:\n- `%s`"
                   (: :format (fennel.macro-path:gsub ";" "`\n- `")))))

(fn report-imported-macros []
  (report-start "Thyme Imported Macros")
  (let [root (get-root-of-modmap)
        reporter (fn [log-path]
                   (when (macro-recorded? log-path)
                     (let [module-name (peek-module-name log-path)
                           fnl-path (peek-fnl-path log-path)
                           msg (: "%s
- source file:
  `%s`
- dependency-map file:
  `%s`" :format module-name fnl-path log-path)]
                       (report-info msg))))]
    (each-file reporter root)))

(fn report-mounted-paths []
  (report-start "Thyme Mounted Paths")
  (let [mounted-paths (RollbackManager.get-mounted-paths)]
    (if (next mounted-paths)
        (do
          ;; TODO: Split reports per rollback kind: config, macro, and module
          (report-info (-> "Th mounted paths:\n- `%s`"
                           (: :format
                              (-> mounted-paths
                                  (table.concat "`\n- `"))))))
        (report-info "No paths are mounted."))))

{:check (fn []
          (report-integrations)
          (report-thyme-disk-info)
          (report-fennel-paths)
          (report-imported-macros)
          (report-thyme-config)
          (report-mounted-paths))}
