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
          (assert.is_same {:foo :bar} (require :foo))))))
  (describe* "can work with the value \"lua\";"
    (var config nil)
    (let [default-debug? vim.env.THYME_DEBUG]
      (before_each (fn []
                     (set vim.env.THYME_DEBUG :1)
                     (tset package.loaded :thyme.config nil)
                     (let [{: get-config} (require :thyme.config)]
                       (set config (get-config)))
                     (set config.fnl-dir "lua")))
      (after_each (fn []
                    (tset package.loaded :thyme.config nil)
                    (set vim.env.THYME_DEBUG default-debug?)))
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
            (assert.is_same {:foo :bar} (require :foo))))))))
