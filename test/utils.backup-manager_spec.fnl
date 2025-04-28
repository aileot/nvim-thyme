(import-macros {: before-each : describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local RollbackManager (require :thyme.utils.rollback))

(fn clear-backup-files! []
  (vim.fn.delete (RollbackManager.get-root) :rf))

(describe* "rollback"
  (before-each (fn []
                 (clear-backup-files!)))
  (it* ".new creates a backup directory."
    (let [label "foo"]
      (RollbackManager.new label ".foobar")
      (->> (vim.fn.isdirectory (RollbackManager.get-root))
           (assert.is_same 1))))
  (it* ".create-module-backup! creates a backup file."
    (let [label "foo"
          module-name "foobar"
          bm (RollbackManager.new label ".fnl")
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
