(import-macros {: describe* : it*} :test.helper.busted-macros)

(local {: remove-context-files!} (include :test.helper.util))

(local thyme (require :thyme))

(local {: search-fnl-module-on-rtp!} (require :thyme.loader.runtime-module))
(local {: search-fnl-macro-on-rtp!} (require :thyme.loader.macro-module))

(describe* "runtime loader failure-reason"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  ;; TODO: Add specs on its rollback loader.
  (it* "should start with \\n"
    (assert.is_true (vim.startswith (search-fnl-module-on-rtp! "invalid-runtime-file")
                                    "\n")))
  (it* "should start with \\nthyme("
    (assert.is_true (vim.startswith (search-fnl-module-on-rtp! "invalid-runtime-file")
                                    "\nthyme(")))
  (it* "should not start with duplicated \\n\\n"
    (assert.is_false (vim.startswith (search-fnl-module-on-rtp! "invalid-runtime-file")
                                     "\n\n"))))

(describe* "macro loader failure-reason"
  ;; TODO: Add specs on its rollback loader.
  (it* "should start with \\n"
    (assert.is_true (vim.startswith (search-fnl-macro-on-rtp! "invalid-macro-file")
                                    "\n")))
  (it* "should start with \\nthyme("
    (assert.is_true (vim.startswith (search-fnl-macro-on-rtp! "invalid-macro-file")
                                    "\nthyme(")))
  (it* "should not start with duplicated \\n\\n"
    (assert.is_false (vim.startswith (search-fnl-macro-on-rtp! "invalid-macro-file")
                                     "\n\n"))))
