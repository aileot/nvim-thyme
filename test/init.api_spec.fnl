(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)
(local {: remove-context-files!} (include :test.helper.util))
(local thyme (require :thyme))

(describe* "thyme.cache.open"
  (after_each (fn []
                (remove-context-files!)))
  (it* "should open a dir a name of whose subdirectory contains literally `compile`"
    (thyme.cache.open)
    (let [fullpath (vim.fn.expand "%:p")]
      (assert.equals :compile
                     (-> fullpath
                         (: :match "compile"))))))
