(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.util))

(local Config (require :thyme.config))

(local RollbackManager (require :thyme.rollback.manager))
;; TODO: Avoid hardcoding params to use ModuleRollbackManager methods.
(local RuntimeModuleRollbackManager (RollbackManager.new :runtime ".lua"))

(local thyme (require :thyme))

(describe* "The fallback-able options"
  (describe* "Config.command.compiler-options"
    (it* "throws no error as getter"
      (assert.has_no_errors #Config.command.compiler-options))
    (it* "throws no error as setter"
      (let [default-compiler-options Config.command.compiler-options]
        (assert.has_no_errors #(set Config.command.compiler-options
                                    {:correlate true}))
        (assert.is_same {:correlate true} Config.command.compiler-options)
        (set Config.command.compiler-options default-compiler-options))))
  (describe* "Config.keymap.compiler-options"
    (it* "throws no error as getter"
      (assert.has_no_errors #Config.keymap.compiler-options))
    (it* "throws no error as setter"
      (let [default-compiler-options Config.keymap.compiler-options]
        (assert.has_no_errors #(set Config.keymap.compiler-options
                                    {:correlate true}))
        (assert.is_same {:correlate true} Config.keymap.compiler-options)
        (set Config.keymap.compiler-options default-compiler-options)))))

(describe* "option fnl-dir"
  (let [default-fnl-dir Config.fnl-dir]
    (setup (fn []
             (thyme.setup)))
    (after_each (fn []
                  (remove-context-files!)
                  (set Config.fnl-dir default-fnl-dir)))
    (describe* "is set to \"fnl\" by default;"
      (describe* "thus, the path (.. (stdpath :config) \"/fnl/foo.fnl\")"
        (it* "can be loaded by `(require :foo)`"
          (let [fnl-file (prepare-config-fnl-file! "foo.fnl" "{:foo :bar}")]
            (assert.is_same {:foo :bar} (require :foo))
            (set package.loaded.foo nil)
            (vim.fn.delete fnl-file)))))
    (describe* "can work with the value \"lua\";"
      (before_each (fn []
                     (set Config.fnl-dir "lua")))
      (describe* "thus, the path (.. (stdpath :config) \"/lua/foo.fnl\")"
        (it* "can be loaded by `(require :foo)`"
          (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{:foo :bar}")]
            (assert.is_same {:foo :bar} (require :foo))
            (set package.loaded.foo nil)
            (vim.fn.delete fnl-path)))))
    (describe* "can work with an empty string \"\";"
      (before_each (fn []
                     (set Config.fnl-dir "")))
      (describe* "thus, the path (.. (stdpath :config) \"/foo.fnl\")"
        (it* "can be loaded by `(require :foo)`"
          (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{:foo :bar}")]
            (assert.is_same {:foo :bar} (require :foo))
            (set package.loaded.foo nil)
            (vim.fn.delete fnl-path)))))))

(describe* "option max-rollbacks"
  (let [default-max-rollbacks Config.max-rollbacks]
    (before_each (fn []
                   (thyme.setup)
                   (set Config.max-rollbacks 3)))
    (after_each (fn []
                  (set Config.max-rollbacks default-max-rollbacks)
                  (remove-context-files!)))
    (it* "limits the number of backups per Fennel module."
      (let [mod :foobar
            filename (.. mod ".fnl")
            backup-handler (RuntimeModuleRollbackManager:backup-handler-of mod)
            fnl-path (prepare-config-fnl-file! filename ":ctx1")]
        (assert.equals 0 (length (backup-handler:list-backup-files)))
        (assert.equals :ctx1 (require mod))
        (tset package.loaded mod nil)
        (vim.cmd :ThymeCacheClear)
        (vim.wait 1)
        (assert.equals 1 (length (backup-handler:list-backup-files)))
        (prepare-config-fnl-file! filename ":ctx2")
        (assert.equals :ctx2 (require mod))
        (tset package.loaded mod nil)
        (vim.cmd :ThymeCacheClear)
        (vim.wait 1)
        (assert.equals 2 (length (backup-handler:list-backup-files)))
        (prepare-config-fnl-file! filename ":ctx3")
        (assert.equals :ctx3 (require mod))
        (tset package.loaded mod nil)
        (vim.cmd :ThymeCacheClear)
        (vim.wait 1)
        (assert.equals 3 (length (backup-handler:list-backup-files)))
        (prepare-config-fnl-file! filename ":ctx4")
        (assert.equals :ctx4 (require mod))
        (tset package.loaded mod nil)
        (vim.cmd :ThymeCacheClear)
        (vim.wait 1)
        (assert.equals 3 (length (backup-handler:list-backup-files)))
        (vim.fn.delete fnl-path)))))
