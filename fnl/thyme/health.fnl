(local fennel (require :fennel))

(local {: get-main-config} (require :thyme.config))

(local (report-start report-info report-ok report-warn report-error)
       (let [health vim.health]
         (if health.start
             (values health.start health.info health.ok health.warn
                     health.error)
             ;; For nvim <0.10.0
             ;; (The support will be dropped w/o deprecation notice.)
             (values health.report_start health.report_info health.report_ok
                     health.report_warn health.report_error))))

(fn report-thyme-config []
  (report-start "Thyme current config on .nvim-thyme.fnl")
  (report-info (fennel.view (get-main-config))))

(fn report-fennel-paths []
  (report-start "Thyme fennel.{path,macro-path}")
  (report-info (.. "fennel.path:\n- " ;
                   (fennel.path:gsub ";" "\n- ")))
  (report-info (.. "fennel.macro-path:\n- " (fennel.macro-path:gsub ";" "\n- "))))

{:check (fn []
          (report-thyme-config)
          (report-fennel-paths))}
