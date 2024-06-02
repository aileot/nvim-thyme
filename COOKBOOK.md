# Cookbook

## Recompile without notice

Though it depends on your workflow, the following snippet can reduce
recompiling process on the next startup very much.

Of course, it will not complete all the compilations if your fnl files depend
on some autocmd events like `BufReadPost`, `FileType`, `VimEnter` `UIEnter`,
`User-VeryLazy` from lazy.nvim, etc.

```fennel
(vim.api.nvim_create_autocmd [:FocusLost :VimLeavePre :VimSuspend]
  {:desc "Compile missing lua cache for the next startup"
   :callback (fn []
               (vim.fn.jobstart [:nvim :--headless :-i :NONE :+q] {:detach true})
               ;; Make sure to return nil not to destroy this autocmd.
               nil)})
```

## .nvim.fnl

```fennel
(vim.api.nvim_create_autocmd :BufWritePost
  {:desc "Compile .nvim.fnl into .nvim.lua for &exrc"
   :pattern :.nvim.fnl
   :callback (fn [a]
               (let [thyme (require :thyme)
                     fnl-path a.match
                     lua-path-to-compile (fnl-path:gsub "%.fnl" :.lua)]
                 (thyme.compile-file! fnl-path lua-path-to-compile)
                 ;; Make sure to return nil not to destroy this autocmd.
                 nil))})
```
