(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: config-filename} (require :thyme.const))

(it* "The config file name is .nvim-thyme.fnl"
  (assert.is_same ".nvim-thyme.fnl" config-filename))

(describe* "The config example file is identified in absolute path"
  (it* "regardless of current working directory"
    (let [prev-const-module (require :thyme.const)
          cwd (vim.uv.cwd)]
      (vim.cmd.cd "~")
      (tset package.loaded :thyme.const nil)
      (let [{: example-config-path} (require :thyme.const)]
        (assert.equals 1 (vim.fn.filereadable example-config-path))
        (assert.is_same ".nvim-thyme.fnl.example"
                        (vim.fs.basename example-config-path))
        (vim.cmd.cd cwd)
        (tset package.loaded :thyme.const prev-const-module)))))
