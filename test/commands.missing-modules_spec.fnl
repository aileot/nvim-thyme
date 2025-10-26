(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file!} (include :test.helper.util))

(local thyme (require :thyme))

(local Config (require :thyme.config))

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
  (it* "should complete missing modules with `require`s by default"
    (let [fnl-path (prepare-config-fnl-file! "missing.fnl" "{:inc #(+ $ 1)}")]
      (assert.equals "2" (execute "Fnl (missing.inc 1)"))
      (set package.loaded.missing nil)
      (vim.fn.delete fnl-path)))
  (describe* "with the option `command.implicit-resolve`"
    (it* "set to `true` should not complete any missing modules"
      (let [perv-target-opt Config.command.implicit-resolve
            fnl-path (prepare-config-fnl-file! "missing.fnl" "{:inc #(+ $ 1)}")]
        (set Config.command.implicit-resolve true)
        (assert.equals "2" (execute "Fnl (missing.inc 1)"))
        (set package.loaded.missing nil)
        (vim.fn.delete fnl-path)
        (set Config.command.implicit-resolve perv-target-opt)))
    (describe* "set to `false` should not complete any missing modules;"
      (it* "thus, it should throw an error due to a compile error: unknown identifier"
        (let [perv-target-opt Config.command.implicit-resolve
              fnl-path (prepare-config-fnl-file! "missing.fnl"
                                                 "{:inc #(+ $ 1)}")]
          (set Config.command.implicit-resolve false)
          (assert.has_errors #(execute "Fnl (missing.inc 1)"))
          (set package.loaded.missing nil)
          (vim.fn.delete fnl-path)
          (set Config.command.implicit-resolve perv-target-opt))))))
