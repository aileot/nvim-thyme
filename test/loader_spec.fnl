(import-macros {: setup* : before-each : after-each : describe* : it*}
               :test.helper.busted-macros)

(include :test.prerequisites)

(local {: remove-context-files!} (include :test.helper.utils))

(local {:loader thyme-loader : define-commands!} (require :thyme))

(local default-config-home (vim.fn.stdpath :config))

(local default-fnl-dir (vim.fs.joinpath default-config-home :fnl))
(local default-lua-dir (vim.fs.joinpath default-config-home :lua))

(local default-fnl-module-path (vim.fs.joinpath default-fnl-dir :foobar.fnl))

(local default-lua-module-path (vim.fs.joinpath default-lua-dir :foobar.lua))

(describe* :loader
  (setup* (fn []
            (define-commands!)))
  (before-each (fn []
                 (-> (vim.fs.dirname default-fnl-module-path)
                     (vim.fn.mkdir :p))
                 (-> (vim.fs.dirname default-lua-module-path)
                     (vim.fn.mkdir :p))
                 (vim.fn.delete default-fnl-module-path)
                 (vim.fn.delete default-lua-module-path)
                 (->> (vim.fn.filereadable default-fnl-module-path)
                      (assert.equals 0))
                 (->> (vim.fn.filereadable default-lua-module-path)
                      (assert.equals 0))
                 (assert.is_not_nil (-> vim.o.runtimepath
                                        (: :find (vim.fn.stdpath :config) ;
                                           1 true)))))
  (after-each (fn []
                (vim.fn.delete default-fnl-module-path)
                (vim.fn.delete default-lua-module-path)
                (remove-context-files!)
                (set package.loaded.foobar nil)
                (vim.cmd "silent % bdelete")))
  (it* "returns a string if specified module is not found"
    (assert.equals :string (type (thyme-loader :foo)))
    (assert.equals :string (type (thyme-loader :bar)))
    (assert.equals :string (type (thyme-loader :foobar))))
  (describe* "cannot load a lua file under lua/ as a module;"
    (it* "thus, thyme.loader returns a string for the module \"foobar\" without any error"
      (vim.cmd "silent ThymeUninstall")
      (-> default-lua-dir
          (vim.fn.mkdir :p))
      (vim.cmd (.. "silent write " default-lua-module-path))
      (-> (vim.fn.filereadable default-lua-module-path)
          (assert.equals 1))
      (assert.equals :string (type (thyme-loader :foobar)))
      (vim.fn.delete default-lua-module-path)))
  (describe* "can load a fnl file under fnl/ as a module by default;"
    (it* "thus, thyme.loader can load the module \"foobar\" without any error"
      (vim.cmd "silent ThymeUninstall")
      (-> default-fnl-dir
          (vim.fn.mkdir :p))
      (vim.cmd (.. "silent write " default-fnl-module-path))
      (-> (vim.fn.filereadable default-fnl-module-path)
          (assert.equals 1))
      (assert.equals :function (type (thyme-loader :foobar)))
      (vim.fn.delete default-fnl-module-path))
    (it* "thus, `require` can load the module \"foobar\" without any error"
      (assert.is_false (pcall require :foobar))
      (vim.cmd (.. "silent write " default-fnl-module-path))
      (assert.is_true (pcall require :foobar))))
  (it* "can restore and load missing module from backup once loaded"
    (vim.cmd (.. "silent write " default-fnl-module-path))
    (assert.equals :function (type (thyme-loader :foobar)))
    (set package.loaded.foobar nil)
    (vim.fn.delete default-fnl-module-path)
    (assert.equals :function (type (thyme-loader :foobar))))
  (it* "cannot restore once loaded module after :ThymeUninstall"
    (vim.cmd (.. "silent write " default-fnl-module-path))
    (assert.equals :function (type (thyme-loader :foobar)))
    (set package.loaded.foobar nil)
    (vim.fn.delete default-fnl-module-path)
    (vim.cmd "silent ThymeUninstall")
    (assert.equals :string (type (thyme-loader :foobar)))))
