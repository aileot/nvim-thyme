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
    2 (vim.cmd (.. "saveas " config-path))
    _ (case (vim.fn.confirm "Aborted proceeding with nvim-thyme. Exit?"
                            "&No\n&yes" 1 :WarningMsg)
        2 (os.exit 1))))

{: prompt-fallback-config!}
