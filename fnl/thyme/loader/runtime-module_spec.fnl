(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)
(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.util))

(local thyme (require :thyme))
(local {: search-fnl-module-on-rtp!} (require :thyme.loader.runtime-module))

(describe* "runtime module loader failure-reason"
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

(describe* "module searcher"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "can load the module `fennel`;"
    (it* "thus, searcher returns a chunk function."
      (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{}")]
        (assert.equals :function (type (search-fnl-module-on-rtp! :fennel)))
        (vim.fn.delete fnl-path))))
  (after_each (fn []
                (let [raw-confirm vim.fn.confirm]
                  (set vim.fn.confirm
                       (fn []
                         (let [idx-yes 2]
                           idx-yes)))
                  (set vim.fn.confirm raw-confirm))))
  (describe* "should find a fennel file in fnl/ dir on vim.o.rtp;"
    (it* "thus, searcher returns a chunk function."
      (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{}")]
        (assert.equals :function (type (search-fnl-module-on-rtp! :foo)))
        (vim.fn.delete fnl-path))))
  (describe* "creates a cache file with the compiled lua result;"
    (it* "thus, searcher for \"foo\" creates a lua cache file named \"foo.lua\"."
      (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{}")]
        (assert.is_same []
                        (vim.fs.find "foo.lua"
                                     {:upward false
                                      :type :file
                                      :path (vim.fn.stdpath :cache)}))
        (search-fnl-module-on-rtp! :foo)
        (assert.equals :foo.lua
                       (-> (vim.fs.find "foo.lua" {:upward false} :type :file
                                        :path (vim.fn.stdpath :cache))
                           (. 1)
                           (vim.fs.basename)))
        (vim.fn.delete fnl-path)))))
