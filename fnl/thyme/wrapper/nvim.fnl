(fn get-runtime-files [pats all?]
  "Find a file in runtime directories.
@param pats string[]
@param all? boolean whether to return all matches or only the first
@return string[]"
  ;; NOTE: This function is defined since nvim__get_runtime is a private
  ;; interface.
  (let [files []]
    (if all?
        (each [_ pat (ipairs pats)]
          (each [_ f (ipairs (vim.api.nvim_get_runtime_file pat all?))]
            (table.insert files f)))
        (each [_ pat (ipairs pats) &until (. files 1)]
          (case (vim.api.nvim_get_runtime_file pat all?)
            [path] (tset files 1 path))))
    files))

{: get-runtime-files}
