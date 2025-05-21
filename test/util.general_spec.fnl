(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-context-fnl-file! : remove-context-files!}
       (include :test.helper.util))

(local {: sorter/files-to-oldest-by-birthtime} (require :thyme.util.general))

(describe* "sorter/files-to-oldest-by-birthtime"
  (after_each (fn []
                (remove-context-files!)))
  (it* "sorts files newest first"
    ;; TODO: Run tests asynchronously.
    (let [a (prepare-context-fnl-file! "a.fnl" "foo")
          ;; NOTE: 5ms interval is required to make birthtimes apart with
          ;; `vim.uv.fs_stat` at least.
          _ (vim.wait 5)
          b (prepare-context-fnl-file! "b.fnl" "bar")
          _ (vim.wait 5)
          c (prepare-context-fnl-file! "c.fnl" "baz")
          files [b a c]]
      (table.sort files sorter/files-to-oldest-by-birthtime)
      (assert.is_same [c b a] files))))
