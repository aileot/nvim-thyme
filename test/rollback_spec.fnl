(import-macros {: before-each : describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.utils))

(local RollbackManager (require :thyme.utils.rollback))
(local TestRollbackManager (RollbackManager.new :test ".fnl"))

(local {: get-config} (require :thyme.config))
(local config (get-config))

(fn clear-backup-files! []
  (vim.fn.delete (TestRollbackManager.get-root) :rf))

(describe* "rollback"
  (before-each (fn []
                 (clear-backup-files!)))
  (it* ".new creates a backup directory."
    (let [label "foo"]
      (TestRollbackManager.new label ".foobar")
      (->> (vim.fn.isdirectory (TestRollbackManager.get-root))
           (assert.is_same 1))))
  (it* ".create-module-backup! creates a backup file."
    (let [label "foo"
          module-name "foobar"
          bm (TestRollbackManager.new label ".fnl")
          stored-path (bm:module-name->active-backup-path module-name)
          filename (.. module-name ".fnl")
          original-path (vim.fs.joinpath (vim.fn.stdpath :config) :fnl filename)]
      (-> (vim.fs.dirname original-path)
          (vim.fn.mkdir :p))
      (vim.fn.writefile ["{:foo :bar}"] original-path)
      (->> (vim.fn.filereadable stored-path)
           (assert.is_same 0))
      (bm:create-module-backup! module-name original-path)
      (->> (vim.fn.filereadable stored-path)
           (assert.is_same 1)))))

(describe* "rollback.cleanup-old-backups!"
  (let [default-max-rollbacks config.max-rollbacks]
    (before_each (fn []
                   (set config.max-rollbacks 3)))
    (after_each (fn []
                  (set config.max-rollbacks default-max-rollbacks)
                  (remove-context-files!)))
    (it* "limits the number of backups per module to `config.max-rollbacks`."
      (let [mod :foobar
            filename (.. mod ".fnl")
            path (prepare-config-fnl-file! filename "ctx1")]
        (assert.equals 0
                       (length (TestRollbackManager:module-name->backup-files mod)))
        (TestRollbackManager:create-module-backup! mod path)
        (assert.equals 1
                       (length (TestRollbackManager:module-name->backup-files mod)))
        (prepare-config-fnl-file! filename "ctx2")
        (vim.wait 1)
        (TestRollbackManager:create-module-backup! mod path)
        (assert.equals 2
                       (length (TestRollbackManager:module-name->backup-files mod)))
        (prepare-config-fnl-file! filename "ctx3")
        (vim.wait 1)
        (TestRollbackManager:create-module-backup! mod path)
        (assert.equals 3
                       (length (TestRollbackManager:module-name->backup-files mod)))
        (prepare-config-fnl-file! filename "ctx4")
        (vim.wait 1)
        (TestRollbackManager:create-module-backup! mod path)
        (assert.equals 4
                       (length (TestRollbackManager:module-name->backup-files mod)))
        (prepare-config-fnl-file! filename "ctx5")
        (vim.wait 1)
        (TestRollbackManager:create-module-backup! mod path)
        (assert.equals 5
                       (length (TestRollbackManager:module-name->backup-files mod)))
        (TestRollbackManager:cleanup-old-backups! mod)
        (assert.equals 3
                       (length (TestRollbackManager:module-name->backup-files mod)))))))
