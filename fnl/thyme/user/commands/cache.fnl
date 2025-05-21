(import-macros {: command!} :thyme.macros)

(local {: lua-cache-prefix} (require :thyme.const))
(local Messenger (require :thyme.util.class.messenger))
(local CommandMessenger (Messenger.new "command/cache"))
(local {: clear-cache!} (require :thyme.compiler.cache))

(local CmdCache {})

(fn CmdCache.open []
  "Open the cache root directory in a new tabpage."
  ;; NOTE: Filer plugin like oil.nvim usually modifies the buf name
  ;; so that `:tab drop` is unlikely to work expectedly.
  ;; NOTE: For unknown reasons, with `vim.cmd` instead of `nvim_exec2` fails to
  ;; open the dir when directly calling this function, though the wrapper
  ;; command `:ThymeCacheOpen` works.
  (vim.api.nvim_exec2 (.. "tab drop " lua-cache-prefix) {}))

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
    {:desc "[thyme] clear the lua cache and dependency map logs"}
    ;; TODO: Or `:confirm` prefix to ask?
    (fn []
      (let [cleared-any? (CmdCache.clear)
            msg (if cleared-any?
                    (.. "clear all the cache under " lua-cache-prefix)
                    (.. "no cache files detected at " lua-cache-prefix))]
        (CommandMessenger:notify! msg)))))

CmdCache
