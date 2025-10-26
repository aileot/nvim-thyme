(import-macros {: describe* : it*} :test.helper.busted-macros)

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
    (assert.equals "3" (execute "Fnl (+ 1 2)")))
  (it* "should leaves the `Fnl` command result in the `messages`"
    (vim.cmd "messages clear")
    (vim.cmd "Fnl (+ 1 2)")
    (assert.equals "3" (execute "messages")
                   "`messages` should contain the result of the Fnl command")
    (vim.cmd "Fnl [1 2]")
    (vim.cmd "Fnl [1 2 3]")
    ;; FIXME: Why is a newline inserted just after the first result `3`?
    (comment (assert.equals "3\n[1 2]\n[1 2 3]" (execute "messages")
                            "`messages` should append the results of the Fnl command")))
  (it* "should display `nil` result"
    (vim.cmd "messages clear")
    (vim.cmd "Fnl nil")
    (assert.equals "nil" (execute "messages")
                   "`messages` should append the results of the Fnl command")))

(describe* "command :Fnl with range"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "set to 0"
    (it* "can evaluate"
      (assert.equals "nil" (execute "0 Fnl")))
    (it* "should evaluate arg regardless of current buffer"
      (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
      (assert.equals "1" (execute "0 Fnl 1"))))
  (describe* "set to %"
    (describe* "but not in a fennel buffer"
      (it* "should ignore current buffer"
        (let [buf-name "foobar"]
          (vim.cmd.edit buf-name)
          (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
          (vim.cmd (.. "bdelete! " buf-name))
          (assert.equals "nil" (execute "% Fnl")))))
    (describe* "in a tmp file buffer"
      (let [tmp-path (os.tmpname)]
        (before_each (fn []
                       (vim.cmd.edit tmp-path)))
        (after_each (fn []
                      (vim.cmd (.. "bdelete! " tmp-path))
                      (vim.fn.delete tmp-path)))
        (it* "cannot evaluate current buffer at tmp dir if not ft=fennel"
          (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
          (assert.equals "nil" (execute "% Fnl")))
        (it* "can evaluate current buffer at tmp dir if ft=fennel"
          (set vim.o.filetype "fennel")
          (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
          (assert.equals "3" (execute "% Fnl")))
        (it* "can interpret local definition in current buffer at tmp dir if ft=fennel"
          (set vim.o.filetype "fennel")
          (vim.api.nvim_buf_set_lines 0 0 -1 true ["(local foo 1)"])
          (assert.equals "1" (execute "% Fnl foo")))))
    (describe* "in not an existing file buffer"
      (before_each (fn []
                     (vim.cmd.new)
                     (set vim.bo.filetype "fennel")))
      (it* "can evaluate current buffer without any args"
        (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
        (assert.equals "3" (execute "% Fnl")))
      (it* "can interpret local definitions in current buffer"
        (vim.api.nvim_buf_set_lines 0 0 -1 true
                                    ["(local foo 1)" "(local bar (+ 1 2))"])
        (assert.equals "1" (execute "% Fnl foo"))
        (assert.equals "3" (execute "% Fnl bar"))))))

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

(describe* "command :FnlCompile"
  (setup (fn []
           (thyme.setup)))
  (it* "should return a Lua compile result of a fennel expression"
    (assert.equals "return (1 + 2)" (execute "FnlCompile (+ 1 2)"))))

(describe* "command :FnlBufCompile"
  (setup (fn []
           (thyme.setup)))
  (it* "should return a Lua compile result of a fennel buffer"
    (let [buf-name "foobar.fnl"]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
      (assert.equals "return (1 + 2)" (execute (.. "FnlBufCompile " buf-name)))
      (vim.cmd (.. "bdelete! " buf-name))))
  (it* "should return a Lua compile result of a unwritten buffer, instead of the actual file"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
          buf-name fnl-path]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2 3)"])
      (assert.equals "return (1 + 2 + 3)"
                     (execute (.. "FnlBufCompile " buf-name)))
      (vim.cmd (.. "bdelete! " buf-name))
      (vim.fn.delete fnl-path))))

(describe* "command :FnlCompileBuf"
  (setup (fn []
           (thyme.setup)))
  (it* "should return a Lua compile result of a fennel buffer"
    (let [buf-name "foobar.fnl"]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
      (assert.equals "return (1 + 2)" (execute (.. "FnlCompileBuf " buf-name)))
      (vim.cmd (.. "bdelete! " buf-name))))
  (it* "should return a Lua compile result of a unwritten buffer, instead of the actual file"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
          buf-name fnl-path]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2 3)"])
      (assert.equals "return (1 + 2 + 3)"
                     (execute (.. "FnlCompileBuf " buf-name)))
      (vim.cmd (.. "bdelete! " buf-name))
      (vim.fn.delete fnl-path))))

(describe* "command :FnlFileCompile"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  ;; (it* "should throw an error if the given file does not contain fennel expression"
  ;;   (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "return 1")]
  ;;     (assert.has_error #(vim.cmd.FnlFileCompile fnl-path))
  ;;     (vim.fn.delete fnl-path)))
  (it* "without args should return a Lua compile result of current fennel buffer"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
          buf-name fnl-path]
      (vim.cmd.edit buf-name)
      (assert.equals "return (1 + 2)" (execute "FnlFileCompile"))
      (vim.cmd (.. "bdelete! " buf-name))
      (vim.fn.delete fnl-path)))
  (it* "can return a Lua compile result of an unloaded fennel file"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")]
      (assert.equals "return (1 + 2)" (execute (.. "FnlFileCompile " fnl-path)))
      (vim.fn.delete fnl-path)))
  (it* "should return a Lua compile result of an actual file, regardless of an unwritten buffer"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
          buf-name fnl-path]
      (vim.cmd.edit buf-name)
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2 3)"])
      (assert.equals "return (1 + 2)" (execute (.. "FnlFileCompile " fnl-path)))
      (vim.cmd (.. "bdelete! " buf-name))
      (vim.fn.delete fnl-path)))
  (it* "should only return a Lua compile result within given range"
    (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
          buf-name fnl-path]
      (vim.cmd.edit buf-name)
      ;; NOTE: `util.fs.write-file!` does not seem to be able to write
      ;; multiline strings at once so `nvim_buf_set_lines` is used as makeshift.
      (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1" "  2" "  3)"])
      (vim.cmd :write)
      (assert.equals "return (1 + 2 + 3)"
                     (execute (.. "FnlFileCompile " fnl-path))
                     "should compile the whole file")
      (assert.equals "return (1 + 2)"
                     (execute (.. "1,2FnlFileCompile " fnl-path))
                     "should compile in a comma-separated given range")
      (assert.equals "return 2" (execute (.. "2FnlFileCompile " fnl-path))
                     "should compile in a oneline range")
      (vim.cmd (.. "bdelete " buf-name))
      (vim.fn.delete fnl-path))))

;; (describe* "command :FnlFileCompile! (with bang `!`)"
;;   ;; TODO: Make `:FnlFileCompile!` write the result to the file.
;;   (setup (fn []
;;            (thyme.setup)))
;;   (after_each (fn []
;;                 (remove-context-files!)))
;;   (it* "should write a Lua compile result of a fennel file"
;;     (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
;;           buf-name fnl-path]
;;       (vim.cmd.edit buf-name)
;;       (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2)"])
;;       (assert.equals "return (1 + 2)" (execute (.. "FnlFileCompile! " buf-name)))
;;       (vim.cmd (.. "bdelete! " buf-name))
;;       (vim.fn.delete fnl-path)))
;;   (it* "should return a Lua compile result of an actual file, instead of a unwritten buffer"
;;     (let [fnl-path (prepare-context-fnl-file! "foo.fnl" "(+ 1 2)")
;;           buf-name fnl-path]
;;       (vim.cmd.edit buf-name)
;;       (vim.api.nvim_buf_set_lines 0 0 -1 true ["(+ 1 2 3)"])
;;       (assert.equals "return (1 + 2)" (execute (.. "FnlFileCompile! " fnl-path)))
;;       (vim.cmd (.. "bdelete! " buf-name))
;;       (vim.fn.delete fnl-path))))
