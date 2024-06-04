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

(fn clear-cache! []
  "Clear lua cache files and other related state files.
@return boolean if `true`, any files are cleared."
  (when (vim.fs.find :*.lua {:type :file
                             :path lua-cache-prefix
                             :limit math.huge})
    (hide-files-in-dir! lua-cache-prefix)
    (clear-dependency-log-files!)
    true))

{: module-name->lua-path : clear-cache!}
