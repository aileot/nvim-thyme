(local {: config-filename : config-path : example-config-path}
       (require :thyme.const))

(local {: file-readable?} (require :thyme.util.fs))

(fn should-fallback? []
  (not (file-readable? config-path)))

(fn display-example-config! []
  (vim.cmd (.. "tabedit " example-config-path))
  ;; Force to apply lazy treesitter syntax.
  (vim.cmd "redraw!"))

(fn prompt-fallback-config! []
  (display-example-config!)
  (case (vim.fn.confirm (: "Missing %s. Copy the sane example config to %s?"
                           :format config-filename (vim.fn.stdpath :config))
                        "&No\n&yes" 1 :Warning)
    2 (let [config-root-dir (vim.fs.dirname config-path)]
        ;; Especially on CI, ~/.config/nvim/ would be missing.
        (-> config-root-dir
            (vim.fn.mkdir :p))
        (vim.cmd (.. "saveas " config-path)))
    _ (case (vim.fn.confirm "Aborted proceeding with nvim-thyme. Exit?"
                            "&No\n&yes" 1 :WarningMsg)
        2 (os.exit 1))))

{: should-fallback? : prompt-fallback-config!}
