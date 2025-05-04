(import-macros {: setup* : before-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(local {: lua-cache-prefix} (require :thyme.const))


(describe* "command"
  (setup* (fn []
            (thyme.setup)))
  (describe* ":ThymeConfigOpen"
    (it* "opens the main config file .nvim-thyme.fnl"
      (vim.cmd :new)
      (vim.cmd :ThymeConfigOpen)
      (assert.equals ".nvim-thyme.fnl" (vim.fn.expand "%:t"))
      (vim.cmd :quit!)))
  (describe* ":ThymeCacheClear"
    (it* "clears lua cache files"
      (vim.cmd "silent ThymeCacheClear")
      (assert.is_nil (next (vim.fs.find (fn [name _path]
                                          (= ".lua" (string.sub name -4)))
                                        {:type :file
                                         :upward false
                                         :path lua-cache-prefix})))))
  (describe* ":ThymeUninstall"
    (it* "deletes all the thyme's cache, state, and data files"
      (->> (+ (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :cache)
                                                   :thyme))
              (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :data)
                                                   :thyme))
              (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :state)
                                                   :thyme)))
           (assert.not_equals 0))
      (vim.cmd "silent ThymeUninstall")
      (assert.equals 0 (vim.fn.isdirectory lua-cache-prefix))
      (->> (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :cache) :thyme))
           (assert.equals 0))
      (->> (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :data) :thyme))
           (assert.equals 0))
      (->> (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :state) :thyme))
           (assert.equals 0)))))
