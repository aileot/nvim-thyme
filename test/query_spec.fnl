(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(describe* "query"
  (describe* "fennel injections"
    (it* "should be applied to `:Fnl` arguments"
      (let [parser (vim.treesitter.get_string_parser "Fnl (+ 1 1)" "vim")]
        (parser:parse true)
        (assert.equals "vim" (-> parser
                                 (: :language_for_range [0 3 0 3])
                                 (: :lang)))
        (assert.equals "fennel" (-> parser
                                    (: :language_for_range [0 5 0 5])
                                    (: :lang)))))
    (it* "should be applied to `:FnlCompile` arguments"
      (let [parser (vim.treesitter.get_string_parser "FnlCompile (+ 1 1)" "vim")]
        (parser:parse true)
        (assert.equals "vim" (-> parser
                                 (: :language_for_range [0 10 0 10])
                                 (: :lang)))
        (assert.equals "fennel" (-> parser
                                    (: :language_for_range [0 11 0 11])
                                    (: :lang)))))
    (it* "should be applied to dropin cmdline arguments"
      (let [parser (vim.treesitter.get_string_parser "(+ 1 1)" "vim")]
        (parser:parse true)
        (assert.equals "fennel" (-> parser
                                    (: :language_for_range [0 1 0 1])
                                    (: :lang)))))))
