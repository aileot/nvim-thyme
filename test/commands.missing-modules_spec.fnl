(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file!} (include :test.helper.util))

(local thyme (require :thyme))

(fn execute [command]
  "Executes a Vim command and returns the trimmed result.
@param command string Vim command to execute.
@return any"
  (-> command
      (vim.fn.execute)
      (vim.trim)))

(describe* "command :Fnl"
  (setup (fn []
           (thyme.setup)))
  (it* "should complete missing definitions with `require`s"
    (let [fnl-path (prepare-config-fnl-file! "missing.fnl" "{:inc #(+ $ 1)}")]
      (assert.equals "2" (execute "Fnl (missing.inc 1)"))
      (set package.loaded.missing nil)
      (vim.fn.delete fnl-path))))
