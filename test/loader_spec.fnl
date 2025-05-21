(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file!
        : prepare-config-lua-file!
        : remove-context-files!} (include :test.helper.util))

(local thyme (require :thyme))
;; WARN: Importing thyme.config here accidentally removes entire
;; thyme.call.nilted in the Makefile "prune" target.
(local Config (require :thyme.config))

(describe* :loader
  (let [raw-confirm vim.fn.confirm
        default-fnl-dir Config.fnl-dir]
    (setup (fn []
             (thyme.setup)))
    (before_each (fn []
                   (set vim.fn.confirm
                        (fn []
                          (let [idx-yes 2]
                            idx-yes)))))
    (after_each (fn []
                  (set vim.fn.confirm raw-confirm)
                  (remove-context-files!)
                  (vim.cmd "% bdelete")))
    (it* "returns a string if specified module is not found"
      (assert.equals :string (type (thyme.loader :foo))
                     "module 'foo' is loaded unexpectedly"))
    (describe* "with fnl-dir=fnl"
      (before_each (fn []
                     (set Config.fnl-dir "fnl")))
      (after_each (fn []
                    (set Config.fnl-dir default-fnl-dir)))
      (describe* "should not load a lua file under lua/ as a module;"
        (it* "thus, thyme.loader returns a string for the module \"foo\" without any error"
          (let [lua-path (prepare-config-lua-file! :foo.lua "return nil")]
            (assert.equals :string (type (thyme.loader :foo)))
            (vim.fn.delete lua-path))))
      (describe* "can load a fnl file under fnl/ as a module by default;"
        (it* "thus, thyme.loader can load the module \"foo\" without any error"
          (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{}")]
            (assert.equals :function (type (thyme.loader :foo)))
            (vim.fn.delete fnl-path))))
      (it* "thus, `require` can load the module \"foo\" without any error"
        (assert.has_error #(require :foo))
        (set package.loaded.foo nil)
        (let [fnl-path (prepare-config-fnl-file! "foo.fnl" "{}")]
          (assert.has_no_error #(require :foo))
          (set package.loaded.foo nil)
          (vim.fn.delete fnl-path))))
    (it* "can restore and load missing module from backup once loaded"
      (let [fnl-path (prepare-config-fnl-file! :foo.fnl "{}")]
        (assert.equals :function (type (thyme.loader :foo))
                       "failed to load module 'foo' first")
        (vim.fn.delete fnl-path)
        (assert.equals :function (type (thyme.loader :foo))
                       "failed to load once-loaded module 'foo' after deletion")))
    (it* "cannot restore once loaded module after :ThymeUninstall"
      (let [fnl-path (prepare-config-fnl-file! :foo.fnl "{}")]
        (assert.equals :function (type (thyme.loader :foo)))
        (vim.fn.delete fnl-path)
        (vim.cmd "ThymeUninstall")
        (assert.equals :string (type (thyme.loader :foo)))))))
