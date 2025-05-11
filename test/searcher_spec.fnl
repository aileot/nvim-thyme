(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)
(local {: remove-context-files!} (include :test.helper.utils))

(local thyme (require :thyme))
(local {: search-fnl-module-on-rtp!} (require :thyme.searcher.module))

(describe* "module searcher"
  (setup (fn []
           (thyme.setup)))
  (describe* "can load the module `fennel`;"
    (it* "thus, searcher returns a chunk function."
      (assert.equals :function (type (search-fnl-module-on-rtp! :fennel)))))
  (let [fnl-dir (-> (vim.fn.stdpath :config)
                    (vim.fs.joinpath :fnl))
        fnl-path (-> fnl-dir
                     (vim.fs.joinpath "foo.fnl"))]
    (before_each (fn []
                   (-> fnl-dir
                       (vim.fn.mkdir :p))
                   (remove-context-files!)
                   (vim.cmd.write fnl-path)))
    (after_each (fn []
                  (vim.fn.delete fnl-path)
                  (set package.loaded.foo nil)
                  (let [raw-confirm vim.fn.confirm]
                    (set vim.fn.confirm
                         (fn []
                           (let [idx-yes 2]
                             idx-yes)))
                    (remove-context-files!)
                    (set vim.fn.confirm raw-confirm))))
    (describe* "should find a fennel file in fnl/ dir on vim.o.rtp;"
      (it* "thus, searcher returns a chunk function."
        (assert.equals :function (type (search-fnl-module-on-rtp! :foo)))))
    (describe* "creates a cache file with the compiled lua result;"
      (it* "thus, searcher for \"foo\" creates a lua cache file named \"foo.lua\"."
        (assert.is_same []
                        (vim.fs.find "foo.lua"
                                     {:upward false
                                      :type :file
                                      :path (vim.fn.stdpath :cache)}))
        (search-fnl-module-on-rtp! :foo)
        (assert.equals :foo.lua
                       (-> (vim.fs.find "foo.lua"
                                        {:upward false
                                         :type :file
                                         :path (vim.fn.stdpath :cache)})
                           (. 1)
                           (vim.fs.basename)))))))
