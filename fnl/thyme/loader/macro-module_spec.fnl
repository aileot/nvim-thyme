(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)
(local {: remove-context-files!} (include :test.helper.util))

(local thyme (require :thyme))

(local {: search-fnl-macro-on-rtp!} (require :thyme.loader.macro-module))

(describe* "macro module loader failure-reason as 2nd return value"
  ;; TODO: Add specs on its rollback loader.
  (it* "should start with \\n"
    (assert.is_true (vim.startswith (select 2
                                            (search-fnl-macro-on-rtp! "invalid-macro-file"))
                                    "\n")))
  (it* "should start with \\nthyme("
    (assert.is_true (vim.startswith (select 2
                                            (search-fnl-macro-on-rtp! "invalid-macro-file"))
                                    "\nthyme(")))
  (it* "should not start with duplicated \\n\\n"
    (assert.is_false (vim.startswith (select 2
                                             (search-fnl-macro-on-rtp! "invalid-macro-file"))
                                     "\n\n"))))
