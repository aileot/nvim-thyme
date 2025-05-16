(import-macros {: setup* : before-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-context-fnl-file! : remove-context-files!}
       (include :test.helper.util))

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
  (it* "should evaluate a fennel expression"
    (assert.equals "3" (execute "Fnl (+ 1 2)"))))

(describe* "command :FnlBuf"
  (setup (fn []
           (thyme.setup)))
  (it* "should evaluate a buffer as a fennel expression"
    (let [buf-name "foobar.fnl"]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
      (assert.equals "3" (execute (.. "FnlBuf " buf-name)))
      (vim.cmd (.. "bdelete! " buf-name))))
  (it* "should evaluate a unwritten buffer, instead of the actual file"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
          buf-name fnl-path]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2 3)"])
      (assert.not_equals "3" (execute (.. "FnlBuf " buf-name)))
      (assert.equals "6" (execute (.. "FnlBuf " buf-name)))
      (vim.cmd (.. "bdelete! " buf-name))
      (vim.fn.delete fnl-path))))

(describe* "command :FnlFile"
  (setup (fn []
           (thyme.setup)))
  (it* "should evaluate a fennel file"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")]
      (vim.cmd.FnlFile fnl-path)
      (assert.equals "3" (execute (.. "FnlFile " fnl-path)))
      (vim.fn.delete fnl-path)))
  (it* "should evaluate an actual file, instead of a unwritten buffer"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
          buf-name fnl-path]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2 3)"])
      (assert.equals "3" (execute (.. "FnlFile " fnl-path)))
      (vim.cmd (.. "bdelete! " buf-name))
      (vim.fn.delete fnl-path))))
