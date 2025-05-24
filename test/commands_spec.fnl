(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file!
        : prepare-context-fnl-file!
        : prepare-context-lua-file!
        : remove-context-files!} (include :test.helper.util))

(local {: lua-cache-prefix} (require :thyme.const))
(local thyme (require :thyme))

(describe* "command"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
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
    (let [raw-confirm vim.fn.confirm]
      (before_each (fn []
                     (set vim.fn.confirm
                          (fn []
                            (let [idx-yes 2]
                              idx-yes)))))
      (after_each (fn []
                    (set vim.fn.confirm raw-confirm)
                    (remove-context-files!)))
      (it* "deletes all the thyme's cache, state, and data files"
        (let [ctx1 "{:foo :bar}"
              mod :foobar
              fnl-path (.. mod ".fnl")]
          (prepare-config-fnl-file! fnl-path ctx1)
          (require mod)
          (tset package.loaded mod nil)
          (->> (+ (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :cache)
                                                       :thyme))
                  (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :data)
                                                       :thyme))
                  (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :state)
                                                       :thyme)))
               (assert.not_equals 0))
          (vim.cmd :ThymeUninstall)
          (assert.equals 0 (vim.fn.isdirectory lua-cache-prefix))
          (->> (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :cache)
                                                    :thyme))
               (assert.equals 0))
          (->> (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :data)
                                                    :thyme))
               (assert.equals 0))
          (->> (vim.fn.isdirectory (vim.fs.joinpath (vim.fn.stdpath :state)
                                                    :thyme))
               (assert.equals 0)))))))

(describe* "command"
  (describe* ":FnlAlternate"
    (before_each (fn []
                   (thyme.setup)))
    (after_each (fn []
                  (remove-context-files!)))
    (describe* "(for the files compiled by thyme)"
      (it* "opens a compiled lua file for current fnl file."
        (let [path (prepare-config-fnl-file! "foo.fnl" :foo)]
          (vim.cmd.edit path)
          (vim.cmd :FnlAlternate)
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl")
          (require :foo)
          (vim.cmd :FnlAlternate)
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")
          (vim.cmd.bdelete path)
          (vim.cmd :bdelete)
          (vim.fn.delete path)
          (vim.fn.delete (vim.fn.expand "%"))
          (set package.loaded.foo nil))))
    (describe* "(for the files not compiled by thyme)"
      (it* "keeps /path/to/foo.fnl if /path/to/foo.lua does not exist."
        (let [path (prepare-context-fnl-file! "foo.fnl" :foo)]
          (vim.cmd.edit path)
          (vim.cmd :FnlAlternate)
          (assert.is_not_same (vim.fn.expand "%:t") "foo.lua")
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl")
          (vim.cmd.bdelete path)
          (vim.cmd :bdelete)
          (vim.fn.delete path)
          (vim.fn.delete (vim.fn.expand "%"))))
      (it* "keeps /path/to/foo.lua if /path/to/foo.fnl does not exist."
        (let [path (prepare-context-lua-file! "foo.lua" :foo)]
          (vim.cmd.edit path)
          (vim.cmd :FnlAlternate)
          (assert.is_not_same (vim.fn.expand "%:t") "foo.fnl")
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")
          (vim.cmd.bdelete path)
          (vim.cmd :bdelete)
          (vim.fn.delete path)
          (vim.fn.delete (vim.fn.expand "%"))))
      (it* "opens /path/to/foo.lua for /path/to/foo.fnl"
        (let [path (prepare-context-fnl-file! "foo.fnl" :foo)]
          (prepare-context-lua-file! "foo.lua" :foo)
          (vim.cmd.edit path)
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl")
          (vim.cmd :FnlAlternate)
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")
          (vim.cmd.bdelete path)
          (vim.cmd :bdelete)
          (vim.fn.delete path)
          (vim.fn.delete (vim.fn.expand "%"))))
      (it* "opens /path/to/foo.fnl for /path/to/foo.lua"
        (let [path (prepare-context-lua-file! "foo.lua" :foo)]
          (prepare-context-fnl-file! "foo.fnl" :foo)
          (vim.cmd.edit path)
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")
          (vim.cmd :FnlAlternate)
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl")
          (vim.cmd.bdelete path)
          (vim.cmd :bdelete)
          (vim.fn.delete path)
          (vim.fn.delete (vim.fn.expand "%")))))))

(describe* "command :ThymeRollbackSwitch"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  (it* "throws error if no backup exists for specified module."
    ;; NOTE: `vim.cmd.Foobar` format cannot suppress errors with `pcall`.
    (assert.has_error #(vim.cmd "ThymeRollbackSwitch unexisted")))
  (describe* "for module"
    ;; TODO: Do not hardcode `module/` backup dir.
    (let [backup-kind "runtime"]
      (describe* "with applying `require` to a fnl module twice or more but changing its contents"
        (let [ctx1 "{:foo :bar}"
              ctx2 "{:foo :baz}"
              mod :foobar
              fnl-path (.. mod ".fnl")]
          (before_each (fn []
                         (prepare-config-fnl-file! fnl-path ctx1)
                         (require mod)
                         (tset package.loaded mod nil)
                         (vim.cmd :ThymeCacheClear)
                         (prepare-config-fnl-file! fnl-path ctx2)
                         ;; Make sure the backup filename is changed.
                         (vim.wait 1)
                         (require mod)
                         (tset package.loaded mod nil)))
          (it* "shows ui to select backup."
            (var asked? false)
            (let [raw-ui-select vim.ui.select]
              (set vim.ui.select
                   (fn [items _opts cb]
                     (set asked? true)
                     (cb (. items 1))))
              (vim.cmd.ThymeRollbackSwitch (.. backup-kind "/" mod))
              (assert.is_true asked?)
              (set vim.ui.select raw-ui-select))))))))

(describe* "command :ThymeRollbackMount"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "for module"
    ;; TODO: Do not hardcode `module/` backup dir.
    (let [backup-kind "runtime/"]
      (it* "will force `require` to load module from the mounted backup."
        (let [mod :foobar
              fnl-path (.. mod ".fnl")
              ctx1 "1"
              ctx2 "2"]
          (prepare-config-fnl-file! fnl-path ctx1)
          (assert.equals (tonumber ctx1) (require mod))
          (tset package.loaded mod nil)
          (prepare-config-fnl-file! fnl-path ctx2)
          (vim.cmd.ThymeRollbackMount (.. backup-kind mod))
          (vim.cmd :ThymeCacheClear)
          (assert.equals (tonumber ctx1) (require mod))
          (tset package.loaded mod nil)
          (vim.cmd.ThymeRollbackUnmountAll)
          (vim.cmd :ThymeCacheClear)
          (assert.equals (tonumber ctx2) (require mod))
          (tset package.loaded mod nil))))))

(describe* "command :ThymeRollbackUnmountAll"
  (setup (fn []
           (thyme.setup)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "for module"
    ;; TODO: Do not hardcode `module/` backup dir.
    (let [backup-kind "runtime"]
      (describe* "removes all mounted rollbacks;"
        (it* "thus, `:UnmountAll` should make `nvim` ignore the last mounted module"
          (let [mod :foobar
                filename (.. mod ".fnl")
                ctx1 "1"
                ctx2 "2"
                path (prepare-config-fnl-file! filename ctx1)]
            (assert.equals 1 (require mod))
            (tset package.loaded mod nil)
            (vim.cmd :ThymeCacheClear)
            (vim.cmd.ThymeRollbackMount (.. backup-kind "/" mod))
            (prepare-config-fnl-file! filename ctx2)
            (assert.equals 1 (require mod))
            (tset package.loaded mod nil)
            (vim.cmd.ThymeRollbackUnmountAll)
            (assert.equals 2 (require mod))
            (tset package.loaded mod nil)
            (vim.fn.delete path)))))))
