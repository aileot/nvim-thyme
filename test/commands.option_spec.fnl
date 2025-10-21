(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local thyme (require :thyme))
(local Config (require :thyme.config))

(fn execute [command]
  "Executes a Vim command and returns the trimmed result.
@param command string Vim command to execute.
@return any"
  (-> command
      (vim.fn.execute)
      (vim.trim)))

(describe* "option command.preproc"
  (it* "can insert a macro definition"
    (let [prev-preproc Config.command.preproc]
      (set Config.command.preproc
           (fn [fnl-code]
             (.. "(macro inc [a] `(+ ,a 1))\n" fnl-code)))
      ;; NOTE: Config.command change only take effects after thyme.setup.
      (thyme.setup)
      (assert.equals "3" (execute "Fnl (inc 2)"))
      (set Config.command.preproc prev-preproc)
      ;; Reset to the defaults.
      (thyme.setup)))
  (it* "inherits from preproc option at config root when command.preproc is set to falsy"
    (let [prev-preproc Config.preproc
          prev-command-preproc Config.command.preproc]
      (set Config.preproc
           (fn [fnl-code]
             (.. "(macro inc [a] `(+ ,a 1))\n" fnl-code)))
      (set Config.command.preproc false)
      ;; NOTE: Config.command change only take effects after thyme.setup.
      (thyme.setup)
      (assert.equals "3" (execute "Fnl (inc 2)"))
      (set Config.preproc prev-preproc)
      (set Config.command.preproc prev-command-preproc)
      ;; Reset to the defaults.
      (thyme.setup))))
