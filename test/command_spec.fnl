(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: prepare-config-fnl-file!
        : prepare-context-fnl-file!
        : prepare-context-lua-file!
        : remove-context-files!} (include :test.helper.utils))

(local {: define-commands!} (require :thyme))

(describe* "#command"
  (it* "thyme.define-commands! defines :ThymeCacheClear"
    (define-commands!)
    (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                       (. "must not defined")))
    (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                           (. "ThymeCacheClear"))))
  (describe* ":FnlAlternate"
    (before_each (fn []
                   (define-commands!)))
    (after_each (fn []
                  (remove-context-files!)))
    (describe* "(for the files compiled by thyme)"
      (after_each (fn []
                    (set package.loaded.foo nil)))
      (it* "opens a compiled lua file for current fnl file."
        (let [path (prepare-config-fnl-file! "foo.fnl" :foo)]
          (vim.cmd.edit path)
          (vim.cmd "silent FnlAlternate")
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl")
          (require :foo)
          (vim.cmd "silent FnlAlternate")
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")
          (vim.cmd.bdelete path)
          (vim.fn.delete path))))
    (describe* "(for the files not compiled by thyme)"
      (it* "keeps /path/to/foo.fnl if /path/to/foo.lua does not exists."
        (let [path (prepare-context-fnl-file! "foo.fnl" :foo)]
          (vim.cmd.edit path)
          (vim.cmd "silent FnlAlternate")
          (assert.is_not_same (vim.fn.expand "%:t") "foo.lua")
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl")))
      (it* "keeps /path/to/foo.lua if /path/to/foo.fnl does not exists."
        (let [path (prepare-context-lua-file! "foo.lua" :foo)]
          (vim.cmd.edit path)
          (vim.cmd "silent FnlAlternate")
          (assert.is_not_same (vim.fn.expand "%:t") "foo.fnl")
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")))
      (it* "opens /path/to/foo.lua for /path/to/foo.fnl"
        (let [path (prepare-context-fnl-file! "foo.fnl" :foo)]
          (prepare-context-lua-file! "foo.lua" :foo)
          (vim.cmd.edit path)
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl")
          (vim.cmd "silent FnlAlternate")
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")))
      (it* "opens /path/to/foo.fnl for /path/to/foo.lua"
        (let [path (prepare-context-lua-file! "foo.lua" :foo)]
          (prepare-context-fnl-file! "foo.fnl" :foo)
          (vim.cmd.edit path)
          (assert.is_same (vim.fn.expand "%:t") "foo.lua")
          (vim.cmd "silent FnlAlternate")
          (assert.is_same (vim.fn.expand "%:t") "foo.fnl"))))))

(describe* "command :ThymeRollbackSwitch"
  (before_each (fn []
                 (define-commands!)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "for module"
    ;; TODO: Do not hardcode `module/` backup dir.
    (let [backup-label "module/"]
      (it* "will NOT show ui to select if no backup exists for the module."
        (let [ctx1 "{:foo :bar}"
              mod :foobar
              fnl-path (.. mod ".fnl")]
          (prepare-config-fnl-file! fnl-path ctx1)
          (require mod)
          (tset package.loaded mod nil)
          (var asked? false)
          (let [raw-ui-select vim.ui.select]
            (set vim.ui.select
                 (fn [items _opts cb]
                   (set asked? true)
                   (cb (. items 1))))
            (vim.cmd.ThymeRollbackSwitch (.. backup-label "tmp"))
            (assert.is_false asked?)
            (set vim.ui.select raw-ui-select))))
      (it* "will NOT show ui to select if only one backup exists for the module."
        (var asked? false)
        (let [raw-ui-select vim.ui.select]
          (set vim.ui.select (fn [items _opts cb]
                               (set asked? true)
                               (cb (. items 1))))
          (vim.cmd.ThymeRollbackSwitch (.. backup-label "tmp"))
          (assert.is_false asked?)
          (set vim.ui.select raw-ui-select)))
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
                         (vim.wait 1000)
                         (require mod)
                         (tset package.loaded mod nil)))
          (it* "shows ui to select backup."
            (var asked? false)
            (let [raw-ui-select vim.ui.select]
              (set vim.ui.select
                   (fn [items _opts cb]
                     (set asked? true)
                     (cb (. items 1))))
              (vim.cmd.ThymeRollbackSwitch (.. backup-label mod))
              (assert.is_true asked?)
              (set vim.ui.select raw-ui-select))))))))
