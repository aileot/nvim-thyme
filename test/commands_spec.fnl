(import-macros {: setup* : before-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))

(local {: lua-cache-prefix} (require :thyme.const))

(local {: get-config} (require :thyme.config))

(local config (get-config))

(describe* "define-commands!"
  (before-each (fn []
                 (let [commands (vim.api.nvim_get_commands {:builtin false})]
                   (each [name _map (pairs commands)]
                     (vim.api.nvim_del_user_command name)))))
  (describe* "defines user commands dedicated to thyme"
    (it* "e.g., :ThymeCacheClear"
      (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                         (. :ThymeCacheClear)))
      (thyme.setup)
      (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                             (. :ThymeCacheClear)))))
  (describe* "defines fennel interface commands on thyme"
    (it* "e.g., :Fnl"
      (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                         (. :Fnl)))
      (thyme.setup)
      (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                             (. :Fnl)))))
  (describe* "optionally defines arbitrary prefix commands for fennel interface commands"
    (it* "e.g., with prefix `Foobar`, it defines `:FoobarEval`"
      (let [last-fnl-cmd-prefix config.command.fnl-cmd-prefix]
        (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                           (. :FoobarEval)))
        (set config.command.fnl-cmd-prefix "Foobar")
        (thyme.setup)
        (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                               (. :FoobarEval)))
        (set config.command.fnl-cmd-prefix last-fnl-cmd-prefix)
        (thyme.setup)
        (let [commands (vim.api.nvim_get_commands {:builtin false})]
          (each [name _map (pairs commands)]
            (when (vim.startswith name "Foobar")
              (vim.api.nvim_del_user_command name))))
        (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                           (. :FoobarEval)))))))

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
