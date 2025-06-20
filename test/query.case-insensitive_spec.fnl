(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(describe* "case-insensitive query"
  (describe* "should inject lang=fennel"
    (it* "to `:fnl` arguments (lowercase)"
      (let [parser (vim.treesitter.get_string_parser "fnl (+ 1 1)" "vim")]
        (parser:parse true)
        (assert.equals "vim" (-> parser
                                 (: :language_for_range [0 3 0 3])
                                 (: :lang)))
        (assert.equals "fennel" (-> parser
                                    (: :language_for_range [0 5 0 5])
                                    (: :lang)))))))
