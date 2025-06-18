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
    (describe* "in dropin cmdline arguments"
      (it* "should not be applied by non-Fennel expression vim commands"
        (let [cmds [")))" "% <" "1,$ }"]]
          (each [_ cmd (ipairs cmds)]
            (let [parser (vim.treesitter.get_string_parser cmd "vim")]
              (parser:parse true)
              (assert.not_equals "fennel"
                                 (-> parser
                                     (: :language_for_range [0 1 0 1])
                                     (: :lang))
                                 (-> "%q should not be detected as Fennel expression"
                                     (: :format cmd)))))))
      (describe* "should be applied by a Fennel expression"
        (it* "which starts with `(`"
          (let [parser (vim.treesitter.get_string_parser "(+ 1 1)" "vim")]
            (parser:parse true)
            (assert.equals "fennel"
                           (-> parser
                               (: :language_for_range [0 1 0 1])
                               (: :lang)))))
        (it* "which starts with `[`"
          (let [parser (vim.treesitter.get_string_parser "[:foo :bar]" "vim")]
            (parser:parse true)
            (assert.equals "fennel"
                           (-> parser
                               (: :language_for_range [0 1 0 1])
                               (: :lang)))))
        (it* "which starts with `{`"
          (let [parser (vim.treesitter.get_string_parser "{:foo :bar}" "vim")]
            (parser:parse true)
            (assert.equals "fennel"
                           (-> parser
                               (: :language_for_range [0 1 0 1])
                               (: :lang)))))
        (it* "following whitespaces"
          (let [parser (vim.treesitter.get_string_parser "  (+ 1 1)" "vim")]
            (parser:parse true)
            (assert.equals "fennel"
                           (-> parser
                               (: :language_for_range [0 3 0 3])
                               (: :lang)))))
        (it* "following a `:`"
          (let [parser (vim.treesitter.get_string_parser ":(+ 1 1)" "vim")]
            (parser:parse true)
            (assert.equals "fennel"
                           (-> parser
                               (: :language_for_range [0 1 0 1])
                               (: :lang)))))
        (it* "following multiple `:`s and and whitespaces"
          (let [parser (vim.treesitter.get_string_parser ": : : (+ 1 1)" "vim")]
            (parser:parse true)
            (assert.equals "fennel"
                           (-> parser
                               (: :language_for_range [0 8 0 8])
                               (: :lang)))))
        (it* "following another Ex command separated by `|`"
          (let [parser (vim.treesitter.get_string_parser "e | (+ 1 3)" "vim")]
            (parser:parse true)
            (assert.equals "fennel"
                           (-> parser
                               (: :language_for_range [0 5 0 5])
                               (: :lang)))
            (assert.equals "vim"
                           (-> parser
                               (: :language_for_range [0 3 0 3])
                               (: :lang))
                           "expected vim expression before `|`, not Fennel expression")
            (assert.equals "vim"
                           (-> parser
                               (: :language_for_range [0 3 0 3])
                               (: :lang))
                           "expected `|` to be parsed as Vim command, not Fennel expression")))))))
