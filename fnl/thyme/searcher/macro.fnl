(import-macros {: when-not} :thyme.macros)

(local {: file-readable? : read-file} (require :thyme.utils.fs))

(local Messenger (require :thyme.utils.messenger))
(local SearcherMessenger (Messenger.new "macro-searcher"))
(local RollbackLoaderMessenger (Messenger.new "macro-rollback-loader"))

(local {: pcall-with-logger! : is-logged? : log-again!}
       (require :thyme.module-map.callstack))

(local RollbackManager (require :thyme.rollback))
(local MacroRollbackManager (RollbackManager.new :macro ".fnl"))

(local cache {:macro-loaded {}})

(fn macro-module->?chunk [module-name fnl-path]
  (let [fennel (require :fennel)
        Config (require :thyme.config)
        compiler-options Config.compiler-options
        ?env compiler-options.env]
    ;; NOTE: Macro searcher should set "env" field to "_COMPILER" to indicate
    ;; that the module is a macro definition module. In other words, _COMPILER
    ;; indicates the macro module should be evaluated in a compiler environment,
    ;; which provides the functions, `list?`, `sym?`, etc., on which ordinary
    ;; macro definitions depend. Note that, for macro modules, either
    ;; "compilerEnv" or "compiler-env" should be used instead of "env" field.
    (set compiler-options.env :_COMPILER)
    (case (pcall-with-logger! fennel.eval fnl-path nil compiler-options
                              module-name)
      (true result)
      (let [backup-handler (MacroRollbackManager:backup-handler-of module-name)
            backup-path (backup-handler:determine-active-backup-path)]
        (when (and (not= fnl-path backup-path)
                   (backup-handler:should-update-backup? (read-file fnl-path)))
          (backup-handler:write-backup! fnl-path)
          (backup-handler:cleanup-old-backups!))
        (set compiler-options.env ?env)
        #result)
      (_ raw-msg)
      (let [raw-msg-body (-> "%s is found for the macro module %s, but failed to evaluate it in a compiler environment"
                             (: :format fnl-path module-name))
            msg-body (SearcherMessenger:wrap-msg raw-msg-body)
            msg (-> "
%s
\t%s"
                    (: :format msg-body raw-msg))]
        (set compiler-options.env ?env)
        ;; NOTE: Unlike Lua's package.loaders, Fennel macro-searcher
        ;; is supposed to return a function which must returns a table;
        ;; otherwise when the searhcer fails to find a macro module,
        ;; it must return nil. See the implementation of
        ;; search-macro-module in src/fennel/specials.fnl @1276
        (values nil msg)))))

(fn search-fnl-macro-on-rtp! [module-name]
  "Search macro on &rtp.
@param module-name string
@return (fun(): table)|nil a lua chunk, but only expects a macro table as its end; otherwise, returns `nil` preceding an error message in the second return value.
@return nil|string: nil, or an error message."
  ;; NOTE: In spite of __index, it is redundant to filter out the module named
  ;; :fennel.macros, which will never be passed to macro-searchers.
  (let [fennel (require :fennel)
        ?chunk (case (case (MacroRollbackManager:inject-mounted-backup-searcher! fennel.macro-searchers)
                       searcher (searcher module-name))
                 msg|chunk (case (type msg|chunk)
                             ;; NOTE: Discard unwothy msg in the edge
                             ;; cases on initializations.
                             :function
                             msg|chunk))]
    (or ?chunk ;
        (case (case (fennel.search-module module-name fennel.macro-path)
                fnl-path (macro-module->?chunk module-name fnl-path)
                (_ msg) (values nil (SearcherMessenger:wrap-msg msg)))
          chunk chunk
          (_ error-msg)
          (let [backup-handler (MacroRollbackManager:backup-handler-of module-name)
                backup-path (backup-handler:determine-active-backup-path)
                Config (require :thyme.config)]
            (case Config.?error-msg
              msg (values nil msg)
              _ (let [max-rollbacks Config.max-rollbacks
                      rollback-enabled? (< 0 max-rollbacks)]
                  (if (and rollback-enabled? (file-readable? backup-path))
                      (case (macro-module->?chunk module-name backup-path)
                        chunk
                        ;; TODO: As described in the error message below, append
                        ;; thyme-backup-loader independently to fennel.macro-searchers?
                        (let [msg (: "temporarily restore backup for the module %s (created at %s) due to the following error: %s
HINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.
To stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."
                                     :format module-name
                                     (backup-handler:determine-active-backup-birthtime)
                                     error-msg)]
                          (RollbackLoaderMessenger:notify-once! msg
                                                                vim.log.levels.WARN)
                          chunk)
                        (_ msg)
                        (values nil msg))
                      (values nil error-msg)))))))))

(fn overwrite-metatable! [original-table cache-table]
  (case (getmetatable original-table)
    mt (setmetatable cache-table mt))
  (setmetatable original-table
    {:__newindex (fn [self module-name val]
                   ;; NOTE: In spite of __index, it is redundant to filter out
                   ;; the module named :fennel.macros, which will never be set
                   ;; to fennel.macro-loaded.
                   ;; NOTE: The value at fennel.macro-loaded cannot be reset
                   ;; in __index.
                   (if (is-logged? module-name)
                       (do
                         (rawset self module-name nil)
                         (tset cache-table module-name val))
                       (rawset self module-name val)))
     :__index (fn [_ module-name]
                ;; NOTE: __index runs after __newindex runs.
                (case (. cache-table module-name)
                  cached (do
                           (log-again! module-name)
                           cached)))}))

(fn initialize-macro-searcher-on-rtp! [fennel]
  ;; Ref: src/fennel/specials.fnl @1276
  ;; NOTE: In the original, the first is fennel-macro-searcher to search
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
