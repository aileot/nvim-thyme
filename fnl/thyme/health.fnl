(local fennel (require :fennel))

(local {: get-main-config} (require :thyme.config))
(local {: get-runtime-files} (require :thyme.wrapper.nvim))

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
    (reporter (.. "vim.g.parinfer_loaded = " (tostring vim.g.parinfer_loaded))))
  (let [dependency-files [:parser/fennel.so]]
    ;; Note: The files "parser-info/*.revision" should only belong to
    ;; https://github.com/nvim-treesitter/nvim-treesitter.
    (each [_ file (ipairs dependency-files)]
      (case (get-runtime-files [file] false)
        [path] (report-ok (: "%s is detected at %s." :format file path))
        _ (report-warn (: "missing %s." :format file))))))

(fn report-thyme-config []
  (report-start "Thyme .nvim-thyme.fnl")
  (report-info (.. "The current config:\n" (fennel.view (get-main-config)))))

(fn report-fennel-paths []
  (report-start "Thyme fennel.{path,macro-path}")
  (report-info (.. "fennel.path:\n- " ;
                   (fennel.path:gsub ";" "\n- ")))
  (report-info (.. "fennel.macro-path:\n- " (fennel.macro-path:gsub ";" "\n- "))))

(fn report-thyme-disk-info []
  (report-start "Thyme Disk Info")
  ;; WIP: Import paths
  (report-info "WIP: The root path of Lua cache: ")
  (report-info "WIP: The root path of backups for rollback: ")
  (report-info "WIP: The root path of module-mapping: ")
  (report-info "WIP: The root path of pool: "))

{:check (fn []
          (report-integrations)
          (report-thyme-config)
          (report-fennel-paths)
          (report-thyme-disk-info))}
