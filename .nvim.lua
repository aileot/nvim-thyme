 vim.bo.keywordprg = ":Fnl (macro help [cword] `(vim.cmd.help (vim.fn.tr ,(tostring cword) :- :_))) (help"


 if (vim.api.nvim_buf_get_name(0):sub(-4) == ".lua") then vim.bo.buftype = "nofile"


 return nil else return nil end