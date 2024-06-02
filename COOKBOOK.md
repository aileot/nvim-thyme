# Cookbook

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
