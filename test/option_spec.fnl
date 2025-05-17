(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.utils))

(local Config (require :thyme.config))

(local RollbackManager (require :thyme.rollback.manager))
;; TODO: Avoid hardcoding params to use ModuleRollbackManager methods.
(local ModuleRollbackManager (RollbackManager.new :module ".lua"))

(local thyme (require :thyme))

(describe* "option fnl-dir"
  (let [default-fnl-dir Config.fnl-dir]
    (after_each (fn []
                  (remove-context-files!)
                  (set Config.fnl-dir default-fnl-dir)))
    (describe* "is set to \"fnl\" by default;"
      (describe* "thus, the path (.. (stdpath :config) \"/fnl/foo.fnl\")"
        (let [fnl-path (-> (vim.fn.stdpath :config)
                           (.. "/fnl/foo.fnl"))]
          (setup (fn []
                   (assert.is_nil (vim.uv.fs_stat fnl-path))
                   (-> (vim.fs.dirname fnl-path)
                       (vim.fn.mkdir "p"))
                   (vim.fn.writefile ["{:foo :bar}"] fnl-path)
                   (assert.is_not_nil (vim.uv.fs_stat fnl-path))))
          (teardown (fn []
                      (vim.fn.delete fnl-path)
                      (assert.is_nil (vim.uv.fs_stat fnl-path))))
          (it* "can be loaded by `(require :foo)`"
            (assert.is_same {:foo :bar} (require :foo))
            (set package.loaded.foo nil)))))
    (describe* "can work with the value \"lua\";"
      (before_each (fn []
                     (set Config.fnl-dir "lua")))
      (describe* "thus, the path (.. (stdpath :config) \"/lua/foo.fnl\")"
        (let [fnl-path (-> (vim.fn.stdpath :config)
                           (.. "/lua/foo.fnl"))]
          (before_each (fn []
                         (assert.is_nil (vim.uv.fs_stat fnl-path))
                         (-> (vim.fs.dirname fnl-path)
                             (vim.fn.mkdir "p"))
                         (vim.fn.writefile ["{:foo :bar}"] fnl-path)
                         (assert.is_not_nil (vim.uv.fs_stat fnl-path))))
          (after_each (fn []
                        (vim.fn.delete fnl-path)
                        (assert.is_nil (vim.uv.fs_stat fnl-path))))
          (it* "can be loaded by `(require :foo)`"
            (assert.is_same {:foo :bar} (require :foo))
            (set package.loaded.foo nil)))))
    (describe* "can work with an empty string \"\";"
      (before_each (fn []
                     (set Config.fnl-dir "")))
      (describe* "thus, the path (.. (stdpath :config) \"/foo.fnl\")"
        (let [fnl-path (-> (vim.fn.stdpath :config)
                           (.. "/foo.fnl"))]
          (before_each (fn []
                         (assert.is_nil (vim.uv.fs_stat fnl-path))
                         (-> (vim.fs.dirname fnl-path)
                             (vim.fn.mkdir "p"))
                         (vim.fn.writefile ["{:foo :bar}"] fnl-path)
                         (assert.is_not_nil (vim.uv.fs_stat fnl-path))))
          (after_each (fn []
                        (vim.fn.delete fnl-path)
                        (assert.is_nil (vim.uv.fs_stat fnl-path))))
          (it* "can be loaded by `(require :foo)`"
            (assert.is_same {:foo :bar} (require :foo))
            (set package.loaded.foo nil)))))))

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
            backup-handler (ModuleRollbackManager:backup-handler-of mod)]
        (prepare-config-fnl-file! filename ":ctx1")
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
        (assert.equals 3 (length (backup-handler:list-backup-files)))))))
