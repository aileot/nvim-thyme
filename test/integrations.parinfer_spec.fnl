(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)
(local {: remove-context-files!} (include :test.helper.util))

(local thyme (require :thyme))

(describe* "integrated with parinfer,"
  (setup (fn []
           (thyme.setup)))
  (before_each (fn []
                 (assert.is_truthy (vim.o.rtp:find "parinfer"))))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "fnl wrapper commands automatically balance parentheses;"
    (it* "thus, `:Fnl (+ 1 1` results in the same as `:Fnl (+ 1 1)`"
      (assert.equals (vim.fn.execute "Fnl (+ 1 1)")
                     (vim.fn.execute "Fnl (+ 1 1"))))
  (describe* "fnl wrapper commands should balance considering `\r`;"
    (it* "thus, `:Fnl (+ 1 1\r(+ 1 1` results in the same as `:Fnl (+ 1 1)`"
      (assert.equals (vim.fn.execute "Fnl (+ 1 1\r(+ 1 1")
                     (vim.fn.execute "Fnl (+ 1 1")))
    (it* "thus, `:Fnl (+ 1 1\r (+ 1 1` results in the same as `:Fnl (+ 1 1 (+ 1 1)`"
      (assert.equals (vim.fn.execute "Fnl (+ 1 1\r (+ 1 1")
                     (vim.fn.execute "Fnl (+ 1 1 (+ 1 1"))))
  (describe* "fnl wrapper commands should balance considering `\n`;"
    (it* "thus, `:Fnl (+ 1 1\n(+ 1 1` results in the same as `:Fnl (+ 1 1)`"
      (assert.equals (vim.fn.execute "Fnl (+ 1 1\n(+ 1 1")
                     (vim.fn.execute "Fnl (+ 1 1")))
    (it* "thus, `:Fnl (+ 1 1\n (+ 1 1` results in the same as `:Fnl (+ 1 1 (+ 1 1)`"
      (assert.equals (vim.fn.execute "Fnl (+ 1 1\n (+ 1 1")
                     (vim.fn.execute "Fnl (+ 1 1 (+ 1 1"))))
  (describe* "fnl wrapper commands without treesitter parsers,"
    (let [parser-dirs (vim.api.nvim_get_runtime_file "parser" true)
          new-tmp-path #(.. $ ".bk")
          hide-dir! (fn [path]
                      (let [tmp-path (new-tmp-path path)]
                        (assert.not_equals path tmp-path)
                        (vim.uv.fs_rename path tmp-path)
                        (assert.is_nil (vim.uv.fs_stat path))
                        (assert.is_not_nil (vim.uv.fs_stat tmp-path))))
          restore-dir! (fn [path]
                         (let [tmp-path (new-tmp-path path)]
                           (vim.uv.fs_rename tmp-path path)
                           (assert.is_not_nil (vim.uv.fs_stat path))
                           (assert.is_nil (vim.uv.fs_stat tmp-path))))]
      (assert.is_not_same [] (vim.api.nvim_get_runtime_file "parser" true))
      (before_each (fn []
                     (each [_ path (ipairs parser-dirs)]
                       (hide-dir! path))
                     (assert.is_same []
                                     (vim.api.nvim_get_runtime_file "parser"
                                                                    true))))
      (after_each (fn []
                    (each [_ path (ipairs parser-dirs)]
                      (restore-dir! path))
                    (assert.is_same parser-dirs
                                    (vim.api.nvim_get_runtime_file "parser"
                                                                   true))))
      (it* "`:Fnl` does not throw any error"
        (assert.has_no_error #(vim.cmd "Fnl (+ 1 1)"))))))
