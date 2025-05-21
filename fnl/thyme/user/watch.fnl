(import-macros {: when-not} :thyme.macros)

(local {: config-path : lua-cache-prefix} (require :thyme.const))
(local {: file-readable? : assert-is-fnl-file : read-file}
       (require :thyme.util.fs))

(local {: allowed?} (require :thyme.util.trust))
(local Messenger (require :thyme.util.class.messenger))

(local Config (require :thyme.config))

(local Modmap (require :thyme.dependency.unit))
(local DepObserver (require :thyme.dependency.observer))

(local {: write-lua-file-with-backup! : RuntimeModuleRollbackManager}
       (require :thyme.searcher.runtime-module))

(local {: clear-cache!} (require :thyme.compiler.cache))

(local {: compile-file} (require :thyme.wrapper.fennel))

(local WatchMessenger (Messenger.new "watch"))

(macro augroup! [...]
  `(vim.api.nvim_create_augroup ,...))

(macro autocmd! [...]
  `(vim.api.nvim_create_autocmd ,...))

(var ?group nil)

(local Watcher {})

(set Watcher.__index Watcher)

(fn Watcher.get-modmap [self]
  (case (Modmap.try-read-from-file self._fnl-path)
    latest-modmap (set self._modmap latest-modmap))
  self._modmap)

(fn Watcher.get-fnl-path [self]
  (-> (self:get-modmap)
      (: :get-fnl-path)))

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

(fn Watcher.should-update? [self]
  "Check if fnl file is updated and the compiled lua file exists.
@return boolean"
  (let [modmap (self:get-modmap)]
    (if (modmap:macro?)
        ;; TODO: Compare to the backup fnl-path to tell if updated.
        true
        (case (modmap:get-lua-path)
          lua-path (when (file-readable? lua-path)
                     (let [fnl-path (modmap:get-fnl-path)]
                       (not= (read-file lua-path) ;
                             (compile-file fnl-path))))
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
        lua-path (modmap:get-lua-path)]
    (assert (not (modmap:macro?)) "Invalid attempt to recompile macro")
    ;; NOTE: With "module-name" option, macro-searcher can map macro
    ;; dependency.
    ;; TODO: Clear lua cache if necessary.
    (set compiler-options.module-name module-name)
    ;; NOTE: module-map must be cleared before logging, but after getting
    ;; its maps.
    (modmap:clear! fnl-path)
    (case (DepObserver:observe! fennel.compile-string fnl-path lua-path
                                compiler-options module-name)
      (true lua-code) (let [msg (.. "successfully recompile " fnl-path)
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
        (always? strategy) (case (or (raw-strategy:match "^(always%-)(%S+)$")
                                     raw-strategy)
                             ("always-" strategy) (values true strategy)
                             strategy (values false strategy))
        final-strategy (if (file-readable? (self:get-fnl-path))
                           strategy
                           "clear")]
    (when (or always? (self:should-update?))
      (case final-strategy
        :clear-all (when (clear-cache!)
                     (-> (.. "Cleared all the caches under " lua-cache-prefix)
                         (WatchMessenger:notify!)))
        :clear (let [modmap (self:get-modmap)]
                 (when (modmap:clear!)
                   (-> (.. "Cleared the cache for " (modmap:get-fnl-path))
                       (WatchMessenger:notify!)))
                 (self:update-dependent-modules!))
        :recompile (do
                     (self:clear-dependent-module-maps!)
                     (when-not (self:macro?)
                       (self:try-recompile!))
                     (self:update-dependent-modules!))
        :reload (do
                  (self:clear-dependent-module-maps!)
                  (when-not (self:macro?)
                    (self:try-reload!))
                  (self:update-dependent-modules!))
        _ (error (.. "unsupported strategy: " strategy))))))

(fn Watcher.clear-dependent-module-maps! [self]
  "Clear dependent module maps."
  (let [modmap (self:get-modmap)
        dependent-maps (modmap:get-dependent-maps)]
    (each [dependent-fnl-path (pairs dependent-maps)]
      (-> #(-> (Modmap.try-read-from-file dependent-fnl-path)
               (: :clear!))
          (vim.schedule)))))

(fn Watcher.restore-dependent-module-maps! [self]
  "Restore dependent module maps."
  (let [modmap (self:get-modmap)
        dependent-maps (modmap:get-dependent-maps)]
    (each [dependent-fnl-path (pairs dependent-maps)]
      (-> #(let [modmap (Modmap.new dependent-fnl-path)]
             (when (modmap:restorable?)
               (modmap:restore!)))
          (vim.schedule)))))

(fn Watcher.update-dependent-modules! [self]
  "Update dependent modules."
  (let [modmap (self:get-modmap)
        dependent-maps (modmap:get-dependent-maps)]
    (each [_ dependent (pairs dependent-maps)]
      ;; TODO: Wrap `update-module-dependencies!` into
      ;; `uv.new_async`, but does it keep the consistency?
      (when (file-readable? dependent.fnl-path)
        (-> (Watcher.new dependent.fnl-path)
            (: :update!))))))

(fn Watcher.new [fnl-path]
  "Create Watcher instance if available, or return nil.
@param fnl-path string
@return Watcher|nil Watcher if available, otherwise nil"
  (assert-is-fnl-file fnl-path)
  (let [self (setmetatable {} Watcher)]
    (set self._fnl-path fnl-path)
    (case (Modmap.try-read-from-file fnl-path)
      modmap (do
               (set self._modmap modmap)
               self))))

(fn watch-files! [?opts]
  "Add an autocmd in augroup named `ThymeWatch` to watch fennel files.
It overrides the previously defined `autocmd`s if both event and pattern are
the same.
@param ?opts.verbose boolean (default: false) notify if successfully compiled file.
@param ?opts.dependent-files 'delete'|'ignore' (default: 'delete')
@param ?opts.live-reload boolean WIP (default: false)
@param ?opts.event string|string[] autocmd-event
@param ?opts.pattern string|string[] autocmd-pattern
@return number autocmd-id"
  (let [group (or ?group (augroup! :ThymeWatch {}))
        opts (if ?opts
                 (vim.tbl_deep_extend :force Config.watch ?opts)
                 Config.watch)
        callback (fn [{:match fnl-path}]
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
                     nil))]
    (set ?group group)
    (autocmd! opts.event {: group :pattern opts.pattern : callback})))

{: watch-files!}
