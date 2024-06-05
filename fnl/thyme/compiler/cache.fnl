;; TODO: Rename this file more suitable.
(import-macros {: when-not : inc : first : second : error-fmt} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: lua-cache-prefix} (require :thyme.const))
(local {: hide-files-in-dir!} (require :thyme.utils.pool))
(local {: clear-log-files!} (require :thyme.module-map.unit))

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
  ;; PERF: Because compiling always depends on `(require :fennel)`, or
  ;; fennel.lua, just check if fennel.lua is there to tell if the cache
  ;; directory contains any cache file.
  (case (vim.fs.find :fennel.lua {:type :file :path lua-cache-prefix})
    [nil] false
    _ (do
        (hide-files-in-dir! lua-cache-prefix)
        (clear-log-files!)
        true)))

{: module-name->lua-path : clear-cache!}
