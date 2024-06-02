(local fennel (require :fennel))

(fn report-fennel-paths []
  (vim.health.start "Thyme fennel.{path,macro-path}")
  (vim.health.info (.. "fennel.path:\n- " ;
                       (fennel.path:gsub ";" "\n- ")))
  (vim.health.info (.. "fennel.macro-path:\n- "
                       (fennel.macro-path:gsub ";" "\n- "))))

{:check (fn []
          (report-fennel-paths))}
