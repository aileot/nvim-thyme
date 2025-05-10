;; TODO: Rename this file more suitable.
(import-macros {: when-not : inc : first : second : error-fmt} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: lua-cache-prefix} (require :thyme.const))
(local {: hide-files-in-dir!} (require :thyme.utils.pool))
(local Messenger (require :thyme.utils.messenger))
(local CacheMessenger (Messenger.new "cache"))
(local {: clear-module-map-files!} (require :thyme.module-map.unit))

(fn determine-lua-path [module-name]
  "Determine `lua-path` from `module-name`
@param module-name string
@return string"
  ;; NOTE: For macro modules, the lua-path does not matter; otherwise for
  ;; general modules, each module is converted to its own unique lua-path by
  ;; its nature.
  (let [lua-module-path (.. (module-name:gsub "%." Path.sep) :.lua)]
    (Path.join lua-cache-prefix lua-module-path)))

(fn clear-cache! []
  "Clear lua cache files and other related state files.
@return boolean return `true` when all the lua caches are cleared; otherwise, return `false`."
  ;; NOTE: glob is unavailable in vim.fs.find.
  (case (vim.fs.find #(= :.lua ($:sub -4)) {:type :file :path lua-cache-prefix})
    [nil] (let [msg (.. "no cache files detected at " lua-cache-prefix)]
            (CacheMessenger:notify! msg)
            false)
    _ (let [msg (.. "clear all the cache under " lua-cache-prefix)]
        (hide-files-in-dir! lua-cache-prefix)
        (clear-module-map-files!)
        (CacheMessenger:notify! msg)
        true)))

{: determine-lua-path : clear-cache!}
