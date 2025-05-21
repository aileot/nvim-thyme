;; NOTE: This module is likely to get into loop: loop or previous error.
;; This is because the modules that depends on `eval` of the "fennel"
;; module. Load such modules inside the function after the check whether
;; loading module is "fennel" or not.
;; NOTE: This module is only for nvim main-config, never for project.
(import-macros {: require-with-key : lazy-require-with-key} :thyme.macros)

(local {: search-fnl-module-on-rtp!} (require :thyme.searcher.runtime-module))

(local M {:loader search-fnl-module-on-rtp!
          :fennel {:view (lazy-require-with-key :thyme.wrapper.fennel :view)
                   :eval (lazy-require-with-key :thyme.wrapper.fennel :eval)
                   :compile-string (lazy-require-with-key :thyme.wrapper.fennel
                                                          :compile-string)
                   :compile_file (fn [...]
                                   (let [key (if (select 3 ...) :compile-file!
                                                 :compile-file)]
                                     ((require-with-key :thyme.wrapper.fennel
                                                        key) ...)))
                   :compile-file (lazy-require-with-key :thyme.wrapper.fennel
                                                        :compile-file)
                   :compile-file! (lazy-require-with-key :thyme.wrapper.fennel
                                                         :compile-file!)
                   :compile-buf (lazy-require-with-key :thyme.wrapper.fennel
                                                       :compile-buf)
                   :macrodebug (lazy-require-with-key :thyme.wrapper.fennel
                                                      :macrodebug)}
          :cache {:open (lazy-require-with-key :thyme.user.commands.cache :open)
                  :clear (lazy-require-with-key :thyme.user.commands.cache
                                                :clear)}})

(var has-setup? false)
(fn M.setup [?opts]
  "Initialize thyme environment:

- Define keymaps
- Define commands
- Create autocmds to watch loaded fennel files to update compile caches.

```fennel
;; They all works equally.
(let [thyme (require :thyme)]
  (thyme.setup)
  (thyme:setup)
(-> (require :thyme)
    (: :setup)
```

NOTE: To customize options, please edit `.nvim-thyme.fnl` instead; this
function does NOT handle any options.

NOTE: This function is expected to be called after `VimEnter` events wrapped in
`vim.schedule`, or later.

@param ?opts table (default: `{}`)"
  (assert (or (= nil ?opts) (= nil (next ?opts)) (= ?opts M))
          "Please call `thyme.setup` without any args, or with an empty table.")
  (when (or (not has-setup?) ;
            (= :1 vim.env.THYME_DEBUG))
    (let [config (require :thyme.config)
          watch (require :thyme.user.watch)
          keymaps (require :thyme.user.keymaps)
          commands (require :thyme.user.commands)
          dropin (require :thyme.user.dropin)]
      (watch.watch-files! config.watch)
      (keymaps.define-keymaps! config.keymap)
      (commands.define-commands!)
      (dropin.enable-dropin-paren! config.dropin-paren)
      (set has-setup? true))))

(fn propagate-underscored-keys! [tbl key]
  "Supplement underscored keys, which are compatible with Lua format in
addition to the Fennel-styled keys, e.g., add `tbl.foo_bar` in addition to
`tbl.foo-bar!`."
  (let [val (. tbl key)]
    (when (key:find "[^-!]")
      (let [new-key (-> key
                        (: :gsub "!" "")
                        (: :gsub "%-" "_"))]
        (when (= nil (. tbl new-key))
          (tset tbl new-key val))))
    (case (type val)
      :table (each [k (pairs val)]
               (propagate-underscored-keys! val k)))))

(each [k (pairs M)]
  (propagate-underscored-keys! M k))

M
