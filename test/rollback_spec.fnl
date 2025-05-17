(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.utils))

(local RollbackManager (require :thyme.rollback.manager))
(local TestRollbackManager (RollbackManager.new :test ".fnl"))

(local Config (require :thyme.config))

(fn clear-backup-files! []
  (vim.fn.delete (TestRollbackManager.get-root) :rf))

(describe* "rollback"
  (before_each (fn []
                 (clear-backup-files!)))
  (after_each (fn []
                (remove-context-files!)))
  (it* ".new creates a backup directory."
    (let [kind "foo"]
      (TestRollbackManager.new kind ".foobar")
      (->> (vim.fn.isdirectory (TestRollbackManager.get-root))
           (assert.is_same 1))))
  (it* ".create-module-backup! creates a backup file."
    (let [kind "foo"
          module-name "foobar"
          rollback-manager (TestRollbackManager.new kind ".fnl")
          backup-handler (rollback-manager:backup-handler-of module-name)
          stored-path (backup-handler:determine-active-backup-path)
          filename (.. module-name ".fnl")
          original-path (vim.fs.joinpath (vim.fn.stdpath :config) :fnl filename)]
      (-> (vim.fs.dirname original-path)
          (vim.fn.mkdir :p))
      (vim.fn.writefile ["{:foo :bar}"] original-path)
      (->> (vim.fn.filereadable stored-path)
           (assert.is_same 0))
      (backup-handler:write-backup! original-path)
      (->> (vim.fn.filereadable stored-path)
           (assert.is_same 1)))))

(describe* "rollback.cleanup-old-backups!"
  (before_each (fn []
                 (set Config.max-rollbacks 3)))
  (after_each (fn []
                (set Config.max-rollbacks nil)
                (remove-context-files!)))
  (it* "limits the number of backups per module to `config.max-rollbacks`."
    (let [mod :foobar
          filename (.. mod ".fnl")
          path (prepare-config-fnl-file! filename "ctx1")
          backup-handler (TestRollbackManager:backup-handler-of mod)]
      (assert.equals 0 (length (backup-handler:list-backup-files)))
      (backup-handler:write-backup! path)
      (assert.equals 1 (length (backup-handler:list-backup-files)))
      (prepare-config-fnl-file! filename "ctx2")
      (vim.wait 1)
      (backup-handler:write-backup! path)
      (assert.equals 2 (length (backup-handler:list-backup-files)))
      (prepare-config-fnl-file! filename "ctx3")
      (vim.wait 1)
      (backup-handler:write-backup! path)
      (assert.equals 3 (length (backup-handler:list-backup-files)))
      (prepare-config-fnl-file! filename "ctx4")
      (vim.wait 1)
      (backup-handler:write-backup! path)
      (assert.equals 4 (length (backup-handler:list-backup-files)))
      (prepare-config-fnl-file! filename "ctx5")
      (vim.wait 1)
      (backup-handler:write-backup! path)
      (assert.equals 5 (length (backup-handler:list-backup-files)))
      (backup-handler:cleanup-old-backups!)
      (assert.equals 3 (length (backup-handler:list-backup-files))))))
