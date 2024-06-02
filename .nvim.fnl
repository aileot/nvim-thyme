(set vim.o.keywordprg
     ":Fnl (macro help [cword] `(vim.cmd.help (vim.fn.tr ,(tostring cword) :- :_))) (help")
(vim.print (vim.fn.bufname))
;; (let [id (vim.api.nvim_create_augroup :.nvim.fnl)]
;;   (vim.api.nvim_create_autocmd [:BufWritePost :FileChangedShellPost]
;;                               {:pattern ""}))
