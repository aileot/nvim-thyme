(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: remove-context-files!} (include :test.helper.utils))

(local {: get-config} (require :thyme.config))
(local config (get-config))

(describe* "option fnl-dir"
  (let [default-fnl-dir config.fnl-dir]
    (after_each (fn []
                  (remove-context-files!)
                  (set config.fnl-dir default-fnl-dir)))
    (describe* "is set to \"fnl\" by default;"
      (describe* "thus, the path (.. (stdpath :config) \"/fnl/foo.fnl\")"
        (let [fnl-path (-> (vim.fn.stdpath :config)
                           (.. "/fnl/foo.fnl"))]
          (setup (fn []
                   (assert.is_nil (vim.uv.fs_stat fnl-path))
                   (-> (vim.fs.dirname fnl-path)
                       (vim.fn.mkdir "p"))
                   (vim.fn.writefile ["{:foo :bar}"] fnl-path)
                   (assert.is_not_nil (vim.uv.fs_stat fnl-path))))
          (teardown (fn []
                      (vim.fn.delete fnl-path)
                      (assert.is_nil (vim.uv.fs_stat fnl-path))))
          (after_each (fn []
                        (set package.loaded.foo nil)))
          (it* "can be loaded by `(require :foo)`"
            (assert.is_same {:foo :bar} (require :foo))))))
    (describe* "can work with the value \"lua\";"
      (before_each (fn []
                     (set config.fnl-dir "lua")))
      (describe* "thus, the path (.. (stdpath :config) \"/lua/foo.fnl\")"
        (let [fnl-path (-> (vim.fn.stdpath :config)
                           (.. "/lua/foo.fnl"))]
          (before_each (fn []
                         (assert.is_nil (vim.uv.fs_stat fnl-path))
                         (-> (vim.fs.dirname fnl-path)
                             (vim.fn.mkdir "p"))
                         (vim.fn.writefile ["{:foo :bar}"] fnl-path)
                         (assert.is_not_nil (vim.uv.fs_stat fnl-path))))
          (after_each (fn []
                        (set package.loaded.foo nil)
                        (vim.fn.delete fnl-path)
                        (assert.is_nil (vim.uv.fs_stat fnl-path))))
          (it* "can be loaded by `(require :foo)`"
            (assert.is_same {:foo :bar} (require :foo))))))
    (describe* "can work with an empty string \"\";"
      (before_each (fn []
                     (set config.fnl-dir "")))
      (describe* "thus, the path (.. (stdpath :config) \"/foo.fnl\")"
        (let [fnl-path (-> (vim.fn.stdpath :config)
                           (.. "/foo.fnl"))]
          (before_each (fn []
                         (assert.is_nil (vim.uv.fs_stat fnl-path))
                         (-> (vim.fs.dirname fnl-path)
                             (vim.fn.mkdir "p"))
                         (vim.fn.writefile ["{:foo :bar}"] fnl-path)
                         (assert.is_not_nil (vim.uv.fs_stat fnl-path))))
          (after_each (fn []
                        (set package.loaded.foo nil)
                        (vim.fn.delete fnl-path)
                        (assert.is_nil (vim.uv.fs_stat fnl-path))))
          (it* "can be loaded by `(require :foo)`"
            (assert.is_same {:foo :bar} (require :foo))))))))
