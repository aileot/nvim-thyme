;; NOTE: This module is likely to get into loop: loop or previous error.
;; This is because the modules that depends on `eval` of the "fennel"
;; module. Load such modules inside the function after the check whether
;; loading module is "fennel" or not.
;; NOTE: This module is only for nvim main-config, never for project.
(import-macros {: require-with-key : lazy-require-with-key} :thyme.macros)

(local {: search-fnl-module-on-rtp!} (require :thyme.searcher.module))

(local M {:loader search-fnl-module-on-rtp!
          :view (lazy-require-with-key :thyme.wrapper.fennel :view)
          :eval (lazy-require-with-key :thyme.wrapper.fennel :eval)
          :compile_file (fn [...]
                          (let [key (if (select 3 ...) :compile-file!
                                        :compile-file)]
                            ((require-with-key :thyme.wrapper.fennel key) ...)))
          :compile-file (lazy-require-with-key :thyme.wrapper.fennel
                                               :compile-file)
          :compile-file! (lazy-require-with-key :thyme.wrapper.fennel
                                                :compile-file!)
          :compile-string (lazy-require-with-key :thyme.wrapper.fennel
                                                 :compile-string)
          :macrodebug (lazy-require-with-key :thyme.wrapper.fennel :macrodebug)
          :define-keymaps! (lazy-require-with-key :thyme.user.keymaps
                                                  :define-keymaps!)
          :define-commands! (lazy-require-with-key :thyme.user.commands
                                                   :define-commands!
                                                   :watch-to-update!)})

(fn M.setup [?opts]
  "Initialize thyme environment:

- Define keymaps
- Define commands
- Create autocmds to watch loaded fennel files to update compile caches.

NOTE: To customize options, please edit `.nvim-thyme.fnl` instead; this
function does NOT handle any options.

NOTE: This function is expected to be called after `VimEnter` events wrapped in
`vim.schedule`, or later.

@param ?opts table (default: `{}`)"
  (assert (or (= nil ?opts) (= nil (next ?opts)))
          "Please call `thyme.setup` without any args, or with an empty table.")
  (let [config (require :thyme.config)
        watch (require :thyme.user.watch)
        keymaps (require :thyme.user.keymaps)
        commands (require :thyme.user.commands)]
    (watch.watch-files! config.watch)
    (keymaps.define-keymaps! config)
    (commands.define-commands! config)))

(each [k v (pairs M)]
  ;; Generate keys compatible with Lua format addition to the Fennel-styled
  ;; keys, e.g., add `M.foo_bar` addition to `M.foo-bar!`.
  (when (k:find "[^-!]")
    (let [new-key (-> k
                      (: :gsub "!" "")
                      (: :gsub "%-" "_"))]
      (when (= nil (. M new-key))
        (tset M new-key v)))))

M
