(import-macros {: when-not : str? : dec} :thyme.macros)

(local fennel (require :fennel))

(local tts (require :thyme.wrapper.treesitter))

(local {: apply-parinfer} (require :thyme.wrapper.parinfer))
(fn make-new-cmd [new-fnl-code {: trailing-parens}]
  "Suggest a new Vim command line to replace the last command with parinfer-ed
`new-fnl-code` in Vim command history.
@param new-fnl-code string expecting a fnl code balanced by parinfer
@param opts.trailing-parens 'omit'|'keep'
@return string a new Vim command line to be substituted to the last command"
  (let [trimmed-new-fnl-code (new-fnl-code:gsub "%s*[%]}%)]*$" "")
        last-cmd (vim.fn.histget ":" -1)]
    (case (last-cmd:find trimmed-new-fnl-code 1 true)
      (idx-start idx-end) (let [prefix (-> last-cmd
                                           (: :sub 1 (dec idx-start)))
                                suffix (-> new-fnl-code
                                           (: :gsub "%s*$" "")
                                           (: :sub (- idx-end idx-start -2)))
                                trimmed-suffix (case trailing-parens
                                                 :omit (suffix:gsub "^[%]}%)]*"
                                                                    "")
                                                 :keep suffix
                                                 ?val
                                                 (error (.. "expected one of `omit` or `keep`; got unknown value for trailing-parens: "
                                                            (vim.inspect ?val))))
                                new-cmd (.. prefix trimmed-new-fnl-code
                                            trimmed-suffix)]
                            new-cmd))))

(fn edit-cmd-history! [new-fnl-code {: method &as opts}]
  "Edit Vim command history with `new-fnl-code`.
@param new-fnl-code string expecting a fnl code balanced by parinfer
@param opts.method 'overwrite'|'append'|'ignore'
@param opts.trailing-parens 'omit'|'keep'"
  (let [methods {:overwrite (fn [new-cmd]
                              (assert (= 1 (vim.fn.histadd ":" new-cmd))
                                      "failed to add new fnl code")
                              ;; NOTE: Delete history entry after adding the
                              ;; renew item just in case to leave clue.
                              (assert (= 1 (vim.fn.histdel ":" -2))
                                      "failed to remove the replaced fnl code"))
                 :append (fn [new-cmd]
                           (assert (= 1 (vim.fn.histadd ":" new-cmd))
                                   "failed to add new fnl code"))
                 :ignore #(comment "Do nothing")}]
    (case (. methods method)
      apply-method (let [new-cmd (make-new-cmd new-fnl-code opts)]
                     (apply-method new-cmd))
      _
      (error (.. "expected one of `overwrite`, `append`, or `ignore`; got unknown method "
                 method)))))

(fn parse-cmd-buf-args [{:args path : line1 : line2}]
  "Parse Vim command arguments for Fennel wrapper command which read buffer lines.
@param args table `:help nvim_parse_cmd`
@return string fnl-code"
  (let [bufnr (if (path:find "^%s*$") 0 (vim.fn.bufnr path))
        fnl-code (-> (vim.api.nvim_buf_get_lines bufnr (dec line1) line2 true)
                     (table.concat "\n"))]
    (values fnl-code)))

(fn parse-cmd-file-args [{:fargs [?path] : line1 : line2}]
  "Parse Vim command arguments for Fennel wrapper command which read lines from a file.
@param args table `:help nvim_parse_cmd`
@return string fnl-code"
  (let [full-path (-> (or ?path "%:p")
                      (vim.fn.expand)
                      (vim.fn.fnamemodify ":p"))]
    ;; NOTE: fs.read-file returns the contents in
    ;; a string while vim.fn.readfile returns in
    ;; a list.
    (-> (vim.fn.readfile full-path "" line2)
        (vim.list_slice line1)
        (table.concat "\n"))))

(fn mk-fennel-wrapper-command-callback [callback
                                        {: lang
                                         : discard-last?
                                         : compiler-options
                                         : cmd-history-opts}]
  "Wrap the `fennel` wrapper callback of thyme.
@param callback fun(fnl-code: string): any
@param opts.lang string? (default: \"fennel\")
@param opts.compiler-options table? (default: same values as main config)
@param opts.cmd-history-opts.method string (default: \"overwrite\")
@param opts.cmd-history-opts.trailing-parens string (default: \"omit\")"
  (fn [{: args : smods}]
    (let [verbose? (< -1 smods.verbose)
          new-fnl-code (-> args
                           ;; NOTE: Otherwise, parinfer seems to ignore
                           ;; carriage return characters.
                           (: :gsub "\r" "\n")
                           (apply-parinfer {: cmd-history-opts}))]
      (when verbose?
        (let [verbose-msg (-> ";;; Source\n%s\n;;; Result"
                              (: :format new-fnl-code))]
          (tts.print verbose-msg)))
      (let [results [(callback new-fnl-code compiler-options)]]
        (case (length results)
          0 (tts.print :nil {: lang})
          last-idx (each [i ?text (ipairs results) ;
                          ;; NOTE: Some function like fennel.compile-string returns
                          ;; additional table at last. That is usually unintended
                          ;; information for users.
                          &until (and discard-last? (<= last-idx i))]
                     (let [text (if (= lang :lua) ?text ;
                                    (fennel.view ?text compiler-options))]
                       (tts.print text {: lang}))))
        (-> #(case (pcall vim.api.nvim_parse_cmd (vim.fn.histget ":") {})
               (true cmdline)
               ;; Exclude wrapped cmd format like `(vim.cmd "Fnl (+ 1 2)"`.
               ;; TODO: More accurate command detection?
               (when (cmdline.cmd:find "^Fnl")
                 (edit-cmd-history! new-fnl-code cmd-history-opts)))
            (vim.schedule))))))

{: parse-cmd-buf-args
 : parse-cmd-file-args
 : mk-fennel-wrapper-command-callback}
