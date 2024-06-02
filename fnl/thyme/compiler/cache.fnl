;; TODO: Rename this file more suitable.
(import-macros {: when-not : inc : first : second : error-fmt} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: lua-cache-prefix} (require :thyme.const))
(local {: hide-files-in-dir!} (require :thyme.utils.pool))
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
  "Delete cache files and the related files."
  (hide-files-in-dir! lua-cache-prefix)
  (clear-dependency-log-files!))

(fn clear-cache! [?opts]
  "Clear lua cache files compiled by nvim-thyme.
@param ?opts.prompt boolean (default: true) Set false to clear cache without prompt"
  ;; TODO: Clear the other cache directories?
  (let [opts (or ?opts {})
        path lua-cache-prefix
        idx-yes 2
        ?idx (when (= false opts.prompt)
               idx-yes)]
    (match (or ?idx ;
               (vim.fn.confirm (: "Remove cache files under %s?" :format path)
                               "&No\n&yes" 1 :Warning))
      idx-yes (do
                (delete-cache-files!)
                (vim.notify (.. "Cleared cache: " path)))
      _ (vim.notify (.. "Abort. " path " is already cleared.")))))

{: module-name->lua-path : clear-cache!}
