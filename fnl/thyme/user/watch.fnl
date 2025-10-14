(import-macros {: when-not} :thyme.macros)

(local {: config-path : lua-cache-prefix} (require :thyme.const))
(local {: file-readable? : assert-is-fnl-file : read-file}
       (require :thyme.util.fs))

(local {: allowed?} (require :thyme.util.trust))
(local Messenger (require :thyme.util.class.messenger))

(local Config (require :thyme.lazy-config))

(local Modmap (require :thyme.dependency.unit))
(local DepObserver (require :thyme.dependency.observer))

(local {: hide-macro-cache! : restore-macro-cache!}
       (require :thyme.loader.macro-module))

(local {: write-lua-file-with-backup! : RuntimeModuleRollbackManager}
       (require :thyme.loader.runtime-module))

(local {: clear-cache!} (require :thyme.compiler.cache))

(local {: compile-file} (require :thyme.wrapper.fennel))

(local WatchMessenger (Messenger.new "autocmd/watch"))

(macro augroup! [...]
  `(vim.api.nvim_create_augroup ,...))

(macro autocmd! [...]
  `(vim.api.nvim_create_autocmd ,...))

(local Watcher {})

(set Watcher.__index Watcher)

(fn Watcher.get-fnl-path [self]
  self._fnl-path)

(fn Watcher.get-modmap [self]
  ;; TODO: Once stable, update ._modmap on the strategies recompile and reload
  ;; for performance?
  (let [fnl-path (self:get-fnl-path)]
    (when (file-readable? fnl-path)
      (case (Modmap.try-read-from-file fnl-path)
        latest-modmap (set self._modmap latest-modmap))))
  self._modmap)

(fn Watcher.get-lua-path [self]
  (-> (self:get-modmap)
      (: :get-lua-path)))

(fn Watcher.get-module-name [self]
  (-> (self:get-modmap)
      (: :get-module-name)))

(fn Watcher.get-depentent-maps [self]
  (-> (self:get-modmap)
      (: :get-depentent-maps)))

(fn Watcher.macro? [self]
  (-> (self:get-modmap)
      (: :macro?)))

(fn Watcher.hide-macro-module! [self]
  (let [module-name (self:get-module-name)]
    (hide-macro-cache! module-name)))

(fn Watcher.restore-macro-module! [self]
  (let [module-name (self:get-module-name)]
    (restore-macro-cache! module-name)))

(fn Watcher.should-update? [self]
  "Check if fnl file is updated and the compiled lua file exists.
@return boolean"
  (let [modmap (self:get-modmap)]
    (if (modmap:macro?)
        ;; TODO: Compare to the backup fnl-path to tell if updated.
        true
        (case (modmap:get-lua-path)
          lua-path (if (file-readable? lua-path)
                       (let [fnl-path (modmap:get-fnl-path)]
                         (not= (read-file lua-path) ;
                               (compile-file fnl-path)))
                       false)
          _ (error (-> "invalid ModuleMap instance for %s: %s"
                       (: :format (modmap:get-module-name) (vim.inspect modmap))))))))

(fn Watcher.count-dependent-modules [self]
  "Count dependent modules.
@return number"
  (let [modmap (self:get-modmap)
        dependent-maps (modmap:get-dependent-maps)]
    (accumulate [i 0 _ (pairs dependent-maps)]
      i)))

(fn Watcher.try-recompile! [self]
  "Try to recompile the module. Restore the last compile cache if failed."
  (let [fennel (require :fennel)
        compiler-options Config.compiler-options
        modmap (self:get-modmap)
        module-name (modmap:get-module-name)
        fnl-path (modmap:get-fnl-path)
        lua-path (modmap:get-lua-path)
        last-chunk (. package.loaded module-name)]
    (assert (not (modmap:macro?)) "Invalid attempt to recompile macro")
    ;; NOTE: With "module-name" option, macro-searcher can map macro
    ;; dependency.
    ;; TODO: Clear lua cache if necessary.
    (set compiler-options.module-name module-name)
    ;; NOTE: module-map must be cleared before logging, but after getting
    ;; its maps.
    (modmap:hide! fnl-path)
    (case (DepObserver:observe! fennel.compile-string fnl-path lua-path
                                compiler-options module-name)
      (true lua-code) (let [msg (.. "successfully recompiled " fnl-path)
                            backup-handler (RuntimeModuleRollbackManager:backup-handler-of module-name)]
                        (write-lua-file-with-backup! lua-path lua-code
                                                     module-name)
                        (backup-handler:cleanup-old-backups!)
                        (WatchMessenger:notify! msg)
                        true)
      (_ error-msg) (let [msg (-> "abort recompiling %s due to the following error:
%s"
                                  (: :format fnl-path error-msg))]
                      (WatchMessenger:notify! msg vim.log.levels.WARN)
                      (tset package.loaded module-name last-chunk)
                      (modmap:restore!)
                      false))))

(fn Watcher.try-reload! [self]
  "Reload the module in current nvim session. Restore the last compile cache if
failed."
  (let [modmap (self:get-modmap)
        modname (modmap:get-module-name)
        last-chunk (. package.loaded modname)]
    (tset package.loaded modname nil)
    (when (modmap:macro?)
      (case (pcall require modname)
        true (WatchMessenger:notify! (.. "Successfully reloaded " modname))
        (false error-msg)
        (let [msg (-> "Failed to reload %s due to the following error:\n%s"
                      (: :format modname error-msg))]
          (tset package.loaded modname last-chunk)
          (WatchMessenger:notify! msg vim.log.levels.ERROR))))))

(fn Watcher.update! [self]
  "Update Lua caches."
  (let [modmap (self:get-modmap)
        raw-strategy (if (modmap:macro?)
                         (or Config.watch.macro-strategy ;
                             Config.watch.strategy)
                         Config.watch.strategy)
        (always? strategy) (case (raw-strategy:match "^(%S-%-)(%S+)$")
                             ("always-" strategy) (values true strategy)
                             _ (values false raw-strategy))
        final-strategy (if (file-readable? (self:get-fnl-path))
                           strategy
                           "clear")]
    (when (or always? (self:should-update?))
      (case final-strategy
        :clear-all (when (clear-cache!)
                     (-> (.. "Cleared all the caches under " lua-cache-prefix)
                         (WatchMessenger:notify!)))
        :clear (let [macro? (self:macro?)
                     modmap (self:get-modmap)
                     ;; NOTE: Make sure get the last dependent-maps before
                     ;; clearing.
                     dependent-maps (modmap:get-dependent-maps)]
                 (when macro?
                   (self:hide-macro-module!))
                 (when (modmap:hide!)
                   (-> (.. "Cleared the cache for " (self:get-fnl-path))
                       (WatchMessenger:notify!)))
                 (self.update-dependent-modules! dependent-maps)
                 (when macro?
                   (self:restore-macro-module!)))
        :recompile (let [macro? (self:macro?)
                         dependent-maps (modmap:get-dependent-maps)]
                     (if macro?
                         (self:hide-macro-module!)
                         (self:try-recompile!))
                     (self.update-dependent-modules! dependent-maps)
                     (when macro?
                       (self:restore-macro-module!)))
        :reload (let [macro? (self:macro?)
                      dependent-maps (modmap:get-dependent-maps)]
                  (if macro?
                      ;; NOTE: When strategy is reload, no need to restore.
                      (self:hide-macro-module!)
                      (self:try-reload!))
                  (self.update-dependent-modules! dependent-maps))
        _ (error (.. "unsupported strategy: " strategy))))))

(fn Watcher.update-dependent-modules! [dependent-maps]
  "Update dependent modules."
  (each [_ dependent (pairs dependent-maps)]
    ;; TODO: Wrap `update-module-dependencies!` into
    ;; `uv.new_async`, but does it keep the consistency?
    (-> #(when (file-readable? dependent.fnl-path)
           (-> (Watcher.new dependent.fnl-path)
               (: :update!)))
        (vim.schedule))))

(fn Watcher.new [fnl-path]
  "Create Watcher instance if available, or return nil.
@param fnl-path string
@return Watcher|nil Watcher if available, otherwise nil"
  (assert-is-fnl-file fnl-path)
  (let [self (setmetatable {} Watcher)]
    (set self._fnl-path fnl-path)
    (when (file-readable? fnl-path)
      (case (Modmap.try-read-from-file fnl-path)
        modmap (do
                 (set self._modmap modmap)
                 self)))))

(fn watch-files! []
  "Add an autocmd in augroup named `ThymeWatch` to watch fennel files.
It overrides the previously defined `autocmd`s if both event and pattern are
the same. The configurations are only modifiable at the `watch` attributes in
`.nvim-thyme.fnl`.
@return number autocmd-id"
  (let [group (augroup! :ThymeWatch {})
        opts Config.watch
        callback (fn [{: buf :match fnl-path}]
                   ;; NOTE: Exclude scheme://uri.fnl
                   ;; NOTE: `<amatch>` against a file name is always expanded to
                   ;; the fullpath with forward slash regardless of &shellslash.
                   (when (and (= "/" (fnl-path:sub 1 1))
                              (= "" (. vim.bo buf :buftype)))
                     (let [resolved-path (vim.fn.resolve fnl-path)]
                       (if (= config-path resolved-path)
                           (do
                             (when (allowed? config-path)
                               ;; Automatically re-trust the user config file
                               ;; regardless of the recorded hash; otherwise, the
                               ;; user will be annoyed being asked to trust
                               ;; his/her config file on every change.
                               (vim.cmd "silent trust"))
                             (when (clear-cache!)
                               (let [msg (.. "Cleared all the cache under "
                                             lua-cache-prefix)]
                                 (WatchMessenger:notify! msg))))
                           (case (Watcher.new fnl-path)
                             watcher (watcher:update!)))
                       ;; Prevent not to destroy the autocmd.
                       nil)))]
    (autocmd! opts.event {: group :pattern opts.pattern : callback})))

{: watch-files!}
