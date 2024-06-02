;; Note: This module is likely to get into loop: loop or previous error.
;; This is because the modules that depends on `eval` of the "fennel"
;; module. Load such modules inside the function after the check whether
;; loading module is "fennel" or not.
;; Note: This module is only for nvim main-config, never for project.
(import-macros {: lazy-require-with-key} :thyme.macros)

(local {: search-fnl-module-on-rtp!} (require :thyme.searcher.module))

(local M {:loader search-fnl-module-on-rtp!
          :view (lazy-require-with-key :thyme.wrapper.fennel :view)
          :eval (lazy-require-with-key :thyme.wrapper.fennel :eval)
          :compile-file! (lazy-require-with-key :thyme.wrapper.fennel
                                                :compile-file!)
          :compile-string (lazy-require-with-key :thyme.wrapper.fennel
                                                 :compile-string)
          :macrodebug (lazy-require-with-key :thyme.wrapper.fennel :macrodebug)
          :check-file! (lazy-require-with-key :thyme.user.check
                                              :check-to-update!)
          :watch-files! (lazy-require-with-key :thyme.user.watch
                                               :watch-to-update!)
          :define-keymaps! (lazy-require-with-key :thyme.user.keymaps
                                                  :define-keymaps!)
          :define-commands! (lazy-require-with-key :thyme.user.commands
                                                   :define-commands!)})

(each [k v (pairs M)]
  ;; Generate keys compatible with Lua format addition to the Fennel-styled
  ;; keys, e.g., add `M.foo_bar` addition to `M.foo-bar!`.
  (when (k:find "[^-!]")
    (let [new-key (-> k
                      (: :gsub "!" "")
                      (: :gsub "%-" "_"))]
      (tset M new-key v))))

M
