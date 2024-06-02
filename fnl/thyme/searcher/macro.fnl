(import-macros {: when-not} :thyme.macros)

(local BackupManager (require :thyme.utils.backup-manager))
(local MacroBackupManager (BackupManager.new :macro))

(local {: file-readable?} (require :thyme.utils.fs))
(local {: pcall-with-logger! : is-logged? : log-again!}
       (require :thyme.module-map.callstack))

(local cache {:macro-loaded {}})

(fn macro-module->?chunk [module-name fnl-path]
  (let [fennel (require :fennel)
        {: get-main-config} (require :thyme.config)
        config (get-main-config)
        compiler-options config.compiler-options
        ?env compiler-options.env]
    ;; Note: Macro searcher should set "env" field to "_COMPILER" to indicate
    ;; that the module is a macro definition module. In other words, _COMPILER
    ;; indicates the macro module should be evaluated in a compiler environment,
    ;; which provides the functions, `list?`, `sym?`, etc., on which ordinary
    ;; macro definitions depend. Note that, for macro modules, either
    ;; "compilerEnv" or "compiler-env" should be used instead of "env" field.
    (set compiler-options.env :_COMPILER)
    (case (pcall-with-logger! fennel.eval fnl-path nil compiler-options
                              module-name)
      (true result)
      (let [backup-path (MacroBackupManager:module-name->backup-path module-name)]
        (set compiler-options.env ?env)
        (when-not (= fnl-path backup-path)
          (MacroBackupManager:backup-module! module-name fnl-path))
        #result)
      (_ msg) (let [msg-prefix (: "
thyme-macro-searcher: %s is found for the macro module %s, but failed to evaluate it in a compiler environment
\t" :format fnl-path module-name)]
                (set compiler-options.env ?env)
                ;; Note: Unlike Lua's package.loaders, Fennel macro-searcher
                ;; is supposed to return a function which must returns a table;
                ;; otherwise when the searhcer fails to find a macro module,
                ;; it must return nil. See the implementation of
                ;; search-macro-module in src/fennel/specials.fnl @1276
                (values nil (.. msg-prefix msg))))))

(fn search-fnl-macro-on-rtp! [module-name]
  "Search macro on &rtp.
  @param module-name string
  @return fun(): table a lua chunk, but only expects a macro table as its end."
  ;; Note: In spite of __index, it is redundant to filter out the module named
  ;; :fennel.macros, which will never be passed to macro-searchers.
  (let [fennel (require :fennel)]
    (case (case (fennel.search-module module-name fennel.macro-path)
            fnl-path (macro-module->?chunk module-name fnl-path)
            (_ msg) (values nil (.. "thyme-macro-searcher: " msg)))
      chunk chunk
      (_ error-msg)
      (let [backup-path (MacroBackupManager:module-name->backup-path module-name)
            {: get-main-config} (require :thyme.config)
            config (get-main-config)
            rollback? config.rollback]
        (if (and rollback? (file-readable? backup-path))
            (case (macro-module->?chunk module-name backup-path)
              chunk
              ;; TODO: As described in the error message below, append
              ;; thyme-backup-loader independently to fennel.macro-searchers?
              (let [msg (: "thyme-macro-rollback-loader: temporarily restore backup for the module %s due to the following error: %s"
                           :format module-name error-msg)]
                (vim.notify_once msg vim.log.levels.WARN)
                chunk)
              (_ msg)
              (values nil msg))
            (values nil error-msg))))))

(fn overwrite-metatable! [original-table cache-table]
  (case (getmetatable original-table)
    mt (setmetatable cache-table mt))
  (setmetatable original-table
    {:__newindex (fn [self module-name val]
                   ;; Note: In spite of __index, it is redundant to filter out
                   ;; the module named :fennel.macros, which will never be set
                   ;; to fennel.macro-loaded.
                   ;; Note: The value at fennel.macro-loaded cannot be reset
                   ;; in __index.
                   (if (is-logged? module-name)
                       (do
                         (rawset self module-name nil)
                         (tset cache-table module-name val))
                       (rawset self module-name val)))
     :__index (fn [_ module-name]
                ;; Note: __index runs after __newindex runs.
                (case (. cache-table module-name)
                  cached (do
                           (log-again! module-name)
                           cached)))}))

(fn initialize-macro-searcher-on-rtp! [fennel]
  ;; Ref: src/fennel/specials.fnl @1276
  ;; Note: In the original, the first is fennel-macro-searcher to search
  ;; through fennel.macro-path; the second is lua-macro-searcher through
  ;; package.path.
  (table.insert fennel.macro-searchers 1 search-fnl-macro-on-rtp!)
  ;; Append the macro-searcher to package.loaders to track dependency even
  ;; when compiler-env is not nil.
  (table.insert package.loaders
                (fn [...]
                  (case (search-fnl-macro-on-rtp! ...)
                    chunk chunk
                    (_ msg) msg)))
  (overwrite-metatable! fennel.macro-loaded cache.macro-loaded))

{: initialize-macro-searcher-on-rtp! : search-fnl-macro-on-rtp!}
