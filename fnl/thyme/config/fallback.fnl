(local {: config-filename : config-path : example-config-path}
       (require :thyme.const))

(fn display-example-config! []
  (vim.cmd (.. "tabedit " example-config-path))
  ;; Force to apply lazy treesitter syntax.
  (vim.cmd "redraw!"))

(fn prompt-fallback-config! []
  (display-example-config!)
  (case (vim.fn.confirm (: "Missing \"%s\" at %s. Copy the sane example config?"
                           :format config-filename (vim.fn.stdpath :config))
                        "&No\n&yes" 1 :Warning)
    2 (do
        (vim.cmd (.. "saveas " config-path))
        (case (vim.fn.confirm "Trust this file? Otherwise, it will ask your trust again on nvim restart"
                              "&No\n&yes" 1 :Question)
          2 (let [buf-name (vim.api.nvim_buf_get_name 0)]
              (assert (= buf-name example-config-path)
                      (-> "expected %s, got %s"
                          (: :format example-config-path buf-name)))
              ;; NOTE: vim.secure.trust specifying path in its arg cannot
              ;; set "allow" to the "action" value.
              ;; NOTE: `:trust` to "allow" cannot take any path as the arg.
              (vim.cmd :trust))
          _ (do
              (vim.secure.trust {:action "remove" :path config-path})
              (case (vim.fn.confirm (-> "Aborted trusting %s. Exit?"
                                        (: :format config-path))
                                    "&No\n&yes" 1 :WarningMsg)
                2 (os.exit 1)))))
    _ (case (vim.fn.confirm "Aborted proceeding with nvim-thyme. Exit?"
                            "&No\n&yes" 1 :WarningMsg)
        2 (os.exit 1))))

{: prompt-fallback-config!}
