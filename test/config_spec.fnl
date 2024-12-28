(import-macros {: describe* : it*} :test.helper.busted-macros)

(include "test.helper.prerequisites")

(local {: get-config} (require :thyme.config))

(local fennel (require :fennel))

(describe* "config interface"
  (describe* ".get-config"
    (let [default-debug? vim.env.THYME_DEBUG]
      (var config nil)
      (describe* "returns the current nvim-thyme config table"
        (before_each (fn []
                       (set vim.env.THYME_DEBUG nil)
                       (set config (get-config))))
        (after_each (fn []
                      (set config nil)
                      (set vim.env.THYME_DEBUG default-debug?)))
        (it* "so that we can get the default :macro-path value without error"
          (assert.has_no_error #config.macro-path))
        (describe* "that does not allow to set any option value for the returned table;"
          (it* "thus, attempt to set a defined option :macro-path to \"/foo/bar\" throws error"
            (assert.has_error #(set config.macro-path "/foo/bar"))))
        (describe* "that does not allow to set any option value;"
          (it* "thus, attempt to set undefined option :foo throws error"
            (assert.has_error #config.foo))))
      (describe* "but with THYME_DEBUG=1,"
        (before_each (fn []
                       (set vim.env.THYME_DEBUG :1)
                       (let [mod-path (vim.fs.joinpath vim.env.REPO_ROOT "fnl"
                                                       "thyme" "config.fnl")]
                         (assert.is_not_nil (vim.uv.fs_stat mod-path))
                         (let [{:get-config get-config-in-debug} (fennel.dofile mod-path)]
                           (set config (get-config-in-debug))))))
        (after_each (fn []
                      (set config nil)
                      (set vim.env.THYME_DEBUG default-debug?)))
        (describe* "returns mutable nvim-thyme config table;"
          (it* "thus, :macro-path can be set to \"/foo/bar\""
            (assert.has_no_error #(set config.macro-path "/foo/bar"))
            (assert.equal "/foo/bar" config.macro-path)))))))
