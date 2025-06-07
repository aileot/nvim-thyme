(import-macros {: describe* : it*} :test.helper.busted-macros)

(local {: remove-context-files!} (include :test.helper.util))

(local {: config-filename} (require :thyme.const))

(it* "The config file name is .nvim-thyme.fnl"
  (assert.is_same ".nvim-thyme.fnl" config-filename))

(describe* "thyme requires `&rtp` literally contains `/thyme/compile`;"
  (let [test-rtp/global (vim.opt.runtimepath:get)
        test-rtp/local [(vim.fn.stdpath :config) vim.env.RUNTIMEPATH]
        thyme-compile-path (vim.fs.joinpath (vim.fn.stdpath :cache) :thyme
                                            :compiled)
        mod/thyme-const (loadfile (-> vim.env.REPO_ROOT
                                      (vim.fs.joinpath "lua" "thyme"
                                                       "const.lua")))]
    (before_each (fn []
                   (tset package.loaded "thyme.const" nil)
                   (set vim.opt.runtimepath test-rtp/local)))
    (after_each (fn []
                  (remove-context-files!)))
    (teardown (fn []
                (set vim.opt.runtimepath test-rtp/global)))
    (it* "thus, loading nvim-thyme without the `/thyme/compile` string in `&rtp` throws error."
      (assert.is_false (pcall require :thyme)))
    (it* "thus, prepended `/thyme/compile` can run nvim-thyme."
      (vim.opt.runtimepath:prepend thyme-compile-path)
      (assert.is_true (pcall mod/thyme-const)))
    (it* "thus, appended `/thyme/compile` can run nvim-thyme."
      (vim.opt.runtimepath:append thyme-compile-path)
      (assert.is_true (pcall mod/thyme-const)))
    (it* "thus, `/thyme/compile` injected between other paths by `prepend` can run nvim-thyme."
      (vim.opt.runtimepath:prepend thyme-compile-path)
      (vim.opt.runtimepath:prepend "/foo/bar")
      (assert.is_true (pcall mod/thyme-const)))
    (it* "thus, `/thyme/compile` injected between other paths by `append` can run nvim-thyme."
      (vim.opt.runtimepath:append thyme-compile-path)
      (vim.opt.runtimepath:append "/foo/bar")
      (assert.is_true (pcall mod/thyme-const)))))
