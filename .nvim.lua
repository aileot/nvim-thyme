 vim.o.keywordprg = ":Fnl (macro help [cword] `(vim.cmd.help (vim.fn.tr ,(tostring cword) :- :_))) (help"

 return vim.print(vim.fn.bufname())