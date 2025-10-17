(local fennel (require :fennel))

(local {: lua-cache-prefix : config-path : thyme-repo-root}
       (require :thyme.const))

(local {: get-config} (require :thyme.config))
(local {: each-file} (require :thyme.util.iterator))
(local {:get-root get-root-of-backup} (require :thyme.rollback.manager))
(local {:get-root get-root-of-pool} (require :thyme.util.pool))
(local {: get-runtime-files} (require :thyme.wrapper.nvim))

(local {:get-root get-root-of-modmap &as ModuleMap}
       (require :thyme.dependency.unit))

(local RollbackManager (require :thyme.rollback.manager))

(local report (if vim.health.start
                  vim.health
                  ;; For nvim <0.10.0
                  ;; (The support will be dropped w/o deprecation notice.)
                  {:start vim.health.report_start
                   :info vim.health.report_info
                   :ok vim.health.report_ok
                   :warn vim.health.report_warn
                   :error vim.health.report_error}))

(fn report-integrations []
  (report.start "Thyme Integrations")
  (let [reporter (if (= nil vim.g.parinfer_loaded)
                     report.warn
                     report.ok)]
    (reporter (-> "`%s`"
                  (: :format
                     (.. "vim.g.parinfer_loaded = "
                         (tostring vim.g.parinfer_loaded))))))
  (let [dependency-files [:parser/fennel.so]]
    ;; NOTE: The files "parser-info/*.revision" should only belong to
    ;; https://github.com/nvim-treesitter/nvim-treesitter.
    (each [_ file (ipairs dependency-files)]
      (case (get-runtime-files [file] false)
        [path] (report.ok (: "`%s` is detected at `%s`." :format file path))
        _ (report.warn (: "missing `%s`." :format file))))))

(fn report-thyme-disk-info []
  (report.start "Thyme Disk Info")
  (let [git-cmd/get-version (-> "git -C %q describe --tags || git -C %q status"
                                (: :format thyme-repo-root thyme-repo-root))]
    (report.info (-> "The version of nvim-thyme: %s"
                     (: :format (-> (vim.fn.system git-cmd/get-version)
                                    ;; Trim the newline at the end.
                                    (: :sub 1 -2))))))
  (report.info (-> "The installation path of nvim-thyme: `%s`"
                   (: :format thyme-repo-root)))
  (report.info (-> "The path to .nvim-thyme.fnl: `%s`" (: :format config-path)))
  (report.info (-> "The root path of Lua cache:  `%s`"
                   (: :format lua-cache-prefix)))
  (report.info (-> "The root path of backups for rollback: `%s`"
                   (: :format (get-root-of-backup))))
  (report.info (-> "The root path of module-mapping: `%s`"
                   (: :format (get-root-of-modmap))))
  (report.info (-> "The root path of pool: `%s`"
                   (: :format (get-root-of-pool)))))

(fn report-thyme-config []
  (report.start "Thyme .nvim-thyme.fnl")
  (let [config (get-config)]
    ;; TODO: Dump the file contents in .nvim-thyme.fnl instead?
    ;; NOTE: To inject fennel syntax, `<` must be put at the head of the line,
    ;; but health does not allow it.
    (report.info (-> "The current config:

%s
"
                     (: :format (fennel.view config))))))

(fn report-fennel-paths []
  (report.start "Thyme fennel.{path,macro-path}")
  (report.info (-> "fennel.path:\n- `%s`" ;
                   (: :format (fennel.path:gsub ";" "`\n- `"))))
  (report.info (-> "fennel.macro-path:\n- `%s`"
                   (: :format (fennel.macro-path:gsub ";" "`\n- `")))))

(fn report-imported-macros []
  (report.start "Thyme Imported Macros")
  (let [root (get-root-of-modmap)
        reporter (fn [log-path]
                   (let [modmap (ModuleMap.read-from-log-file log-path)]
                     (when (modmap:macro?)
                       (let [module-name (modmap:get-module-name)
                             fnl-path (modmap:get-fnl-path)
                             dependent-list (modmap:pp-dependent-list)
                             msg (-> "%s
- source file:
  `%s`
- dependent modules:
%s"
                                     (: :format module-name fnl-path
                                        dependent-list))]
                         (report.info msg)))))]
    (each-file reporter root)))

(fn report-mounted-paths []
  (report.start "Thyme Mounted Paths")
  ;; TODO: Replace `.list-mounted-paths`, or just remove this check?
  (let [mounted-paths (RollbackManager.list-mounted-paths)]
    (if (next mounted-paths)
        (let [resolved-paths (icollect [_ path (ipairs mounted-paths)]
                               (vim.uv.fs_realpath path))]
          ;; TODO: Split reports per rollback kind: config, macro, and module
          (report.info (-> "The mounted paths:\n- `%s`"
                           (: :format
                              (-> resolved-paths
                                  (table.concat "`\n- `"))))))
        (report.info "No paths are mounted."))))

{:check (fn []
          (report-integrations)
          (report-thyme-disk-info)
          (report-fennel-paths)
          (report-thyme-config)
          (report-mounted-paths)
          (report-imported-macros))}
