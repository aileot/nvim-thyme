(import-macros {: command!} :thyme.macros)

(local {: lua-cache-prefix} (require :thyme.const))

(local {: clear-cache!} (require :thyme.compiler.cache))

(local CmdCache {})

(fn CmdCache.open []
  "Open the cache root directory in a new tabpage."
  ;; NOTE: Filer plugin like oil.nvim usually modifies the buffer name
  ;; so that `:tab drop` is unlikely to work expectedly.
  (vim.cmd (.. "tab drop " lua-cache-prefix)))

(fn CmdCache.clear []
  "Clear the lua cache and dependency map logs."
  (clear-cache!))

(fn CmdCache.setup! []
  "Define thyme cache commands."
  (command! :ThymeCacheOpen
    {:desc "[thyme] open the cache root directory"}
    CmdCache.open)
  (command! :ThymeCacheClear
    ;; NOTE: No args will be allowed because handling module-map would
    ;; be a bit complicated.
    {:bar true
     :bang true
     :desc "[thyme] clear the lua cache and dependency map logs"}
    ;; TODO: Or `:confirm` prefix to ask?
    (fn []
      (if (CmdCache.clear)
          (vim.notify (.. "Cleared cache: " lua-cache-prefix))
          (vim.notify (.. "No cache files detected at " lua-cache-prefix))))))

CmdCache
