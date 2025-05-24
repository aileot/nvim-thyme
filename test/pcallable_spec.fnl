(import-macros {: describe* : it*} :test.helper.busted-macros)

(include "test.helper.prerequisites")

(local {: lua-cache-prefix} (require :thyme.const))

(describe* "thyme.call.cache.clear"
  (it* "can be called without error."
    (assert.has_no_error #(require "thyme.call.cache.clear"))
    (tset package.loaded "thyme.call.cache.clear" nil)))

(describe* "thyme.call.cache.open"
  (before_each (fn []
                 (vim.cmd :new)))
  (after_each (fn []
                (vim.cmd :only)))
  ;; (it* "should open the same directory as `:ThymeCacheOpen` opened."
  ;;   (vim.cmd "ThymeCacheOpen")
  ;;   (let [buf-name (vim.api.nvim_buf_get_name 0)]
  ;;     (vim.cmd :new)
  ;;     (assert.not_equals buf-name (vim.api.nvim_buf_get_name 0))
  ;;     (require "thyme.call.cache.open")
  ;;     ;; FIXME: Why the buf name gets empty?
  ;;     (assert.equals buf-name (vim.api.nvim_buf_get_name 0))))
  (it* "should open the cache directory."
    (assert.not_equals lua-cache-prefix (vim.api.nvim_buf_get_name 0))
    (require "thyme.call.cache.open")
    (tset package.loaded "thyme.call.cache.open" nil)
    (assert.equals lua-cache-prefix
                   (-> (vim.api.nvim_buf_get_name 0)
                       (: :gsub "/$" "")))))

(describe* "thyme.call.setup"
  (it* "can be called without error."
    (assert.has_no_error #(require "thyme.call.setup"))
    (tset package.loaded "thyme.call.setup" nil)))

(describe* "Invalid tie-in thyme.call interfaces"
  (describe* "whose wrapping function require some arguments"
    (describe* "including thyme.call.fennel interfaces"
      (describe* "like thyme.call.fennel.eval"
        (it* "throws error."
          (assert.has_error #(require "thyme.call.fennel.eval")))))))
