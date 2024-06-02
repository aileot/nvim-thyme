(local fennel (require :fennel))

(local {: get-main-config} (require :thyme.config))

(fn report-thyme-config []
  (vim.health.start "Thyme current config on .nvim-thyme.fnl")
  (vim.health.info (fennel.view (get-main-config))))

(fn report-fennel-paths []
  (vim.health.start "Thyme fennel.{path,macro-path}")
  (vim.health.info (.. "fennel.path:\n- " ;
                       (fennel.path:gsub ";" "\n- ")))
  (vim.health.info (.. "fennel.macro-path:\n- "
                       (fennel.macro-path:gsub ";" "\n- "))))

{:check (fn []
          (report-thyme-config)
          (report-fennel-paths))}
