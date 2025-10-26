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
    (it* "set to `true` should complete missing modules in the arguments"
      (let [perv-target-opt Config.command.implicit-resolve
            foo-path (prepare-config-fnl-file! "foo.fnl" "{:inc #(+ $ 1)}")
            bar-path (prepare-config-fnl-file! "bar.fnl" "{:twice #(* $ 2)}")]
        (set Config.command.implicit-resolve true)
        (assert.equals "4" (execute "Fnl (-> 1 (foo.inc) (bar.twice)"))
        (set package.loaded.foo nil)
        (set package.loaded.bar nil)
        (vim.fn.delete foo-path)
        (vim.fn.delete bar-path)
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

(describe* "command `:verbose Fnl`"
  (setup (fn []
           (thyme.setup)))
  (it* "should also display completed `require`s in the output."
    (let [fnl-path (prepare-config-fnl-file! "missing.fnl" "{:inc #(+ $ 1)}")
          output (execute "verbose Fnl (missing.inc 1)")]
      (assert.is_true (string.find output "require.missing"))
      (set package.loaded.missing nil)
      (vim.fn.delete fnl-path))))
