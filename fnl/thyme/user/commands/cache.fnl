(import-macros {: command!} :thyme.macros)

(local {: lua-cache-prefix} (require :thyme.const))

(local {: clear-cache!} (require :thyme.compiler.cache))

(local M {})

(fn M.setup! []
  "Define thyme cache commands."
  (command! :ThymeCacheOpen
    {:desc "[thyme] open the cache root directory"}
    (fn []
      ;; NOTE: Filer plugin like oil.nvim usually modifies the buffer name
      ;; so that `:tab drop` is unlikely to work expectedly.
      (vim.cmd (.. "tab drop " lua-cache-prefix))))
  (command! :ThymeCacheClear
    ;; NOTE: No args will be allowed because handling module-map would
    ;; be a bit complicated.
    {:bar true
     :bang true
     :desc "[thyme] clear the lua cache and dependency map logs"}
    ;; TODO: Or `:confirm` prefix to ask?
    (fn []
      (if (clear-cache!)
          (vim.notify (.. "Cleared cache: " lua-cache-prefix))
          (vim.notify (.. "No cache files detected at " lua-cache-prefix))))))

M
