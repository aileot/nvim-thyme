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
                                    (: :lang)))))
    (it* "to `:FN` arguments (omitted)"
      ;; NOTE: Instead, `:Fn` throws another error "E464: Ambiguous use"
      ;; FIXME: Pass the test without preceding `:`
      (let [parser (vim.treesitter.get_string_parser ":FN (+ 1 1)" "vim")]
        (parser:parse true)
        (assert.equals "fennel" (-> parser
                                    (: :language_for_range [0 4 0 4])
                                    (: :lang)))
        (assert.equals "vim" (-> parser
                                 (: :language_for_range [0 2 0 2])
                                 (: :lang)))))
    (it* "to `:FNl` arguments (case-mixed)"
      (let [parser (vim.treesitter.get_string_parser "FNl (+ 1 1)" "vim")]
        (parser:parse true)
        (assert.equals "vim" (-> parser
                                 (: :language_for_range [0 3 0 3])
                                 (: :lang)))
        (assert.equals "fennel" (-> parser
                                    (: :language_for_range [0 5 0 5])
                                    (: :lang)))))))
