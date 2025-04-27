(import-macros {: before-each : describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local BackupManager (require :thyme.utils.backup-manager))

(fn clear-backup-files! []
  (vim.fn.delete (BackupManager.get-root) :rf))

(describe* "utils.backup-manager"
  (before-each (fn []
                 (clear-backup-files!)))
  (it* ".new creates a backup directory."
    (let [label "foo"]
      (BackupManager.new label)
      (->> (vim.fn.isdirectory (BackupManager.get-root))
           (assert.is_same 1))))
  (it* ".create-module-backup! creates a backup file."
    (let [label "foo"
          module-name "foobar"
          bm (BackupManager.new label)
          stored-path (bm:module-name->current-backup-path module-name)
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
