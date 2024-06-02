;; TODO: Rename this file more suitable.
(import-macros {: when-not : inc : first : second : error-fmt} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: lua-cache-prefix} (require :thyme.const))
(local {: clear-dependency-log-files!} (require :thyme.module-map.logger))

(fn module-name->lua-path [module-name]
  "Determine `lua-path` from `module-name`
@param module-name string
@return string"
  ;; Note: For macro modules, the lua-path does not matter; otherwise for
  ;; general modules, each module is converted to its own unique lua-path by
  ;; its nature.
  (let [lua-module-path (.. (module-name:gsub "%." Path.sep) :.lua)]
    (Path.join lua-cache-prefix lua-module-path)))

(fn delete-cache-files! []
  "Delete cache files.
@return number 0 for success, -1 for any failures"
  ;; TODO: vim.fn.delete from Lua might be unsafe; replace it with
  ;; os.remove or uv.fs_unlink/us.fs_rmdir.
  (case (vim.fn.delete lua-cache-prefix :rf)
    0 (do
        (clear-dependency-log-files!) 0)
    _ -1))

(fn clear-cache! [?opts]
  "Clear lua cache files compiled by nvim-thyme.
@param ?opts.prompt boolean (default: true) Set false to clear cache without prompt
@param ?opts.path string? without it, clear cache dir. glob is available."
  ;; TODO: Clear the other cache directories?
  (let [opts (or ?opts {})
        path lua-cache-prefix
        idx-yes 2
        ?idx (when (= false opts.prompt)
               idx-yes)]
    (match (or ?idx ;
               (vim.fn.confirm (: "Remove cache files under %s?" :format path)
                               "&No\n&yes" 1 :Warning))
      idx-yes (if (= 0 (delete-cache-files!))
                  (vim.notify (.. "Cleared cache: " path))
                  (vim.notify (.. "Failed to clear cache " path)
                              vim.log.levels.ERROR))
      _ (vim.notify (.. "Abort. " path " is already cleared.")))))

{: module-name->lua-path : clear-cache!}
