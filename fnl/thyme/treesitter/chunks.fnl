(import-macros {: when-not : inc : dec : first : last} :thyme.macros)

(local {: validate-type : new-matrix} (require :thyme.util.general))
(local {: char-by-char : uncouple-substrings} (require :thyme.util.iterator))

(local Config (require :thyme.config))

(local ts vim.treesitter)
(local hl-cache {})

(local hl-chunk-cache (new-matrix))
(local idx-empty-hl-name true)

(local special-chunk {:whitespace [" "] :newline ["\n"]})

(fn set-hl-chunk-cache! [text ?hl-name]
  (let [?hl-group (when ?hl-name
                    (accumulate [?group nil ;
                                 hl-name (uncouple-substrings ?hl-name ".")
                                 &until ?group]
                      (when (vim.api.nvim_get_hl_id_by_name hl-name)
                        hl-name)))
        hl-chunk [text ?hl-group]
        idx (or ?hl-name idx-empty-hl-name)]
    (tset hl-chunk-cache text idx hl-chunk)
    hl-chunk))

(fn get-hl-chunk-cache [text ?hl-name]
  (let [idx (or ?hl-name idx-empty-hl-name)]
    (?. hl-chunk-cache text idx)))

(fn determine-hl-chunk [text ?hl-name]
  (or (get-hl-chunk-cache text ?hl-name) (set-hl-chunk-cache! text ?hl-name)))

(var priority-matrix {})
(fn initialize-priority-matrix! [row col]
  (set priority-matrix (new-matrix row col 0)))

(fn update-hl-chunk-matrix! [hl-chunk-matrix
                             text
                             ?hl-name
                             metadata
                             ;; In the order that (node:range) returns.
                             row01
                             col01]
  "Override matrix `hl-chunk-matrix` with highlights for `text` considering
`metadata.priority`.
@param hl-chunk-matrix table
@param text string
@param ?hl-name string
@param metadata table
@param row01 integer
@param col01 integer"
  (let [priority (or (tonumber metadata.priority) 0)
        row1 (inc row01)
        col1 (inc col01)
        last-priority (or (. priority-matrix row1 col1) 0)]
    (when (<= last-priority priority)
      (var row row1)
      (var col col1)
      (each [_ char (char-by-char text)]
        (tset priority-matrix row col priority)
        (tset hl-chunk-matrix row col (determine-hl-chunk char ?hl-name))
        (if (= "\n" char)
            (do
              (set row (inc row))
              (set col 1))
            (do
              (set col (inc col))))))))

(fn compose-hl-chunks [text lang-tree]
  "Compose hl-chunks for `text` up to `lang-tree`.
@param text string
@param lang-tree vim.treesitter.LanguageTree
@return table[] a sequence of `[text hl-group]` for `vim.api.nvim_echo`."
  (let [top-row0 0 ;
        top-col0 0
        ;; NOTE: bottom-row0, i.e., end-row0, is excluded by the vim.treesitter
        ;; object method Query:iter_captures.
        bottom-row0 -1
        end-row (-> text
                    (vim.split "\n" {:plain true})
                    (length))
        end-col vim.go.columns
        hl-chunk-matrix (new-matrix end-row end-col special-chunk.whitespace)
        cb (fn [ts-tree tree]
             (when ts-tree
               (let [lang (tree:lang)
                     hl-query (or (. hl-cache lang)
                                  (let [hlq (ts.query.get lang :highlights)]
                                    (tset hl-cache lang hlq)
                                    hlq))
                     iter (hl-query:iter_captures (ts-tree:root) text top-row0
                                                  bottom-row0)]
                 (each [(id node metadata) iter]
                   ;; NOTE: Apply metadata.conceal?
                   (case (. hl-query.captures id)
                     (where (or :spell :nospell))
                     nil
                     (where capture (not (vim.startswith capture "_")))
                     ;; NOTE: underscored capture should not be for
                     ;; highlights, but only for internal use.
                     (let [txt (ts.get_node_text node text)
                           hl-name (.. "@" capture)
                           (row01 col01) (node:range)]
                       (update-hl-chunk-matrix! hl-chunk-matrix txt hl-name
                                                metadata row01 col01)))))))]
    (initialize-priority-matrix! end-row end-col)
    (let [text-with-newline (if (= "\n" (text:sub -1))
                                text
                                ;; NOTE: Insert newline char as the marker to
                                ;; truncate trailing whitespace chunks later.
                                (.. text "\n"))]
      (update-hl-chunk-matrix! hl-chunk-matrix text-with-newline nil {}
                               top-row0 top-col0))
    (doto lang-tree
      (: :parse)
      (: :for_each_tree cb))
    (let [hl-chunks []]
      (for [i 1 end-row]
        (for [j 1 end-col &until (= "\n" (first (. hl-chunk-matrix i j)))]
          (table.insert hl-chunks (. hl-chunk-matrix i j)))
        (table.insert hl-chunks special-chunk.newline))
      (when (not= "\n" (text:sub -1))
        (table.remove hl-chunks))
      (values hl-chunks))))

(λ text->hl-chunks [text ?opts]
  "Convert `text` into `chunks`, parsed with treesitter parser (\"fennel\" one
by default) for `vim.api.nvim_echo`.
@param text string
@param ?opts.lang (default: \"fennel\") treesitter parser language
@return table[] a sequence of `[text hl-group]` for `vim.api.nvim_echo`."
  ;; TODO: Extract iterator, or map function.
  ;; NOTE: trailing whitespaces in each line are ignored, i.e., padding each
  ;; line to vim.go.columns here does not make sense.
  (validate-type :string text)
  (if Config.disable-treesitter-highlights
      [[text]]
      (let [opts (or ?opts {})
            base-lang (or opts.lang :fennel)
            tmp-text (-> (case base-lang
                           ;; Temporarily replace address indicators in pretty print
                           ;; to keep valid syntax tree.
                           :fennel
                           (text:gsub "#<(%a+):(%s+0x%x+)>" "#(%1 %2)")
                           :lua
                           ;; TODO: Why does @field not affect in {%1=%2}?
                           (text:gsub "<(%a+%s+%d+)>" "\"%1\"")
                           _
                           text)
                         (: :gsub "\\" "\\\\"))
            fixed-text (-> text
                           ;; Reset the address indicator adjustments,
                           ;; but keep the escapes.
                           (: :gsub "\\" "\\\\"))]
        (validate-type :table opts)
        (case (pcall ts.get_string_parser tmp-text base-lang)
          (false msg)
          (let [chunks [[text]]]
            (vim.notify_once msg vim.log.levels.WARN)
            chunks)
          (true lang-tree)
          ;; Make sure to destroy
          (compose-hl-chunks fixed-text lang-tree)))))

{: text->hl-chunks}
