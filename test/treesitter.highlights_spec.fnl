(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: text->hl-chunks} (require :thyme.treesitter.chunks))

(describe* "treesitter highlights on nvim-treesitter main"
  (it* "should highlight a fennel expression with a capture group"
    (let [chunks (text->hl-chunks "(+ 1 1)")]
      (assert.is_true (< 1 (length chunks)))
      (each [_ [text hl-group] (ipairs chunks)]
        (assert.is_string text)
        (assert.is_true (or (= nil hl-group)
                            (= "string" (type hl-group)))))))
  (it* "should not lose any characters of the text"
    (let [text "(vim.cmd :echo)"
          chunks (text->hl-chunks text)]
      (assert.equals text
                     (table.concat (vim.tbl_map (fn [[text _]] text) chunks))))))