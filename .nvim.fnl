(set vim.bo.keywordprg
     ":Fnl (macro help [cword] `(vim.cmd.help (vim.fn.tr ,(tostring cword) :- :_))) (help")

(when (-> (vim.api.nvim_buf_get_name 0)
          (: :sub -4)
          (= :.lua))
  (set vim.bo.buftype :nofile))

;; (let [id (vim.api.nvim_create_augroup :.nvim.fnl)]
;;   (vim.api.nvim_create_autocmd [:BufWritePost :FileChangedShellPost]
;;                               {:pattern ""}))
