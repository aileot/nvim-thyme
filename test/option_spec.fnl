(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: remove-context-files!} (include :test.helper.utils))

(describe* "option fnl-dir"
  (after_each (fn []
                (remove-context-files!)))
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
          (assert.is_same {:foo :bar} (require :foo)))))))
