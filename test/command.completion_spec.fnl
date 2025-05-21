(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(include :test.helper.assertions)

(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.util))

(local thyme (require :thyme))

(describe* "command completion"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  (let [backup-kind "runtime"]
    (describe* "for :ThymeRollbackUnmount"
      (it* "only completes the mounted modules"
        (let [mod1 "foo"
              mod2 "bar"
              path1 (prepare-config-fnl-file! (.. mod1 ".fnl") "1")
              path2 (prepare-config-fnl-file! (.. mod2 ".fnl") "2")]
          (require mod1)
          (require mod2)
          (vim.cmd.ThymeRollbackUnmountAll)
          (assert.is_same []
                          (vim.fn.getcompletion "ThymeRollbackUnmount "
                                                "cmdline"))
          (vim.cmd.ThymeRollbackMount (.. backup-kind "/" mod1))
          (assert.is_same [(.. backup-kind "/" mod1)]
                          (vim.fn.getcompletion "ThymeRollbackUnmount "
                                                "cmdline"))
          (vim.cmd.ThymeRollbackMount (.. backup-kind "/" mod2))
          (assert.are.same-in-arbitrary-order [(.. backup-kind "/" mod1)
                                               (.. backup-kind "/" mod2)]
                                              (vim.fn.getcompletion "ThymeRollbackUnmount "
                                                                    "cmdline"))
          (assert.are.not.same-in-arbitrary-order ["macro/unexpected"
                                                   (.. backup-kind "/" mod1)
                                                   (.. backup-kind "/" mod2)]
                                                  (vim.fn.getcompletion "ThymeRollbackUnmount "
                                                                        "cmdline"))
          (vim.cmd.ThymeRollbackUnmountAll)
          (tset package.loaded mod1 nil)
          (tset package.loaded mod2 nil)
          (vim.fn.delete path1)
          (vim.fn.delete path2))))))
