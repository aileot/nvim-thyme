(import-macros {: when-not : str? : dec} :thyme.macros)

(local fennel (require :fennel))

(local tts (require :thyme.treesitter))

(local {: apply-parinfer} (require :thyme.wrapper.parinfer))

(fn make-?new-cmd [new-fnl-code {: trailing-parens}]
  "Suggest a new Vim command line to replace the last command with parinfer-ed
`new-fnl-code` in Vim command history.
@param new-fnl-code string expecting a fnl code balanced by parinfer
@param opts.trailing-parens 'omit'|'keep'
@return string? a new Vim command line to be substituted to the last command"
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
                 :ignore false}]
    (case (. methods method)
      false (comment "Do nothing")
      apply-method (case (make-?new-cmd new-fnl-code opts)
                     new-cmd (apply-method new-cmd))
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

(fn extract-Fnl-cmdline-args [cmdline]
  (case (pcall vim.api.nvim_parse_cmd cmdline {})
    (true parsed)
    ;; Exclude wrapped cmd format like `(vim.cmd "Fnl (+ 1 2)"`.
    ;; TODO: More accurate command detection?
    (if (-> (. parsed :cmd)
            ;; TODO: Limit to `:Fnl` and `:FnlCompile`.
            (string.match "^Fnl"))
        (table.concat parsed.args " ")
        (extract-Fnl-cmdline-args parsed.nextcmd))))

(fn mk-fennel-wrapper-command-callback [callback
                                        {: lang
                                         : compiler-options
                                         : preproc
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
                           (apply-parinfer {: cmd-history-opts})
                           (preproc compiler-options))]
      (when verbose?
        (let [verbose-msg (-> ";;; Source\n%s\n;;; Result"
                              (: :format new-fnl-code))]
          ;; TODO: (low priority) Display verbose messages on extui feature
          ;; expectedly, or just drop `verbose` support?
          (tts.print verbose-msg {:lang "fennel"})))
      (case [(callback new-fnl-code compiler-options)]
        [nil] (tts.print "nil" {: lang})
        [text &as results] (case lang
                             :lua
                             ;; NOTE: It expects `fennel.compile-string` as the
                             ;; `callback`, which should return a Lua compiled code and
                             ;; an extra table, the latter of which is usually unintended
                             ;; information for users.
                             (tts.print text {:lang "lua"})
                             :fennel
                             ;; NOTE Print every result one by one, e.g, `(values 1 2 3)`
                             ;; should print `1`, `2`, and `3`, individually.
                             (each [_ text (ipairs results)]
                               (tts.print (fennel.view text compiler-options)
                                          {:lang "fennel"}))))
      (-> #(let [old-cmdline (vim.fn.histget ":")]
             (case (pcall vim.api.nvim_parse_cmd old-cmdline {})
               (true parsed)
               ;; Exclude wrapped cmd format like `(vim.cmd "Fnl (+ 1 2)"`.
               ;; TODO: More accurate command detection?
               (when (parsed.cmd:find "^Fnl")
                 (let [old-fnl-expr (extract-Fnl-cmdline-args old-cmdline)
                       ;; TODO: Extract parinfer lines.
                       new-fnl-expr (-> old-fnl-expr
                                        (: :gsub "\r" "\n")
                                        (apply-parinfer {: cmd-history-opts}))
                       new-cmdline (.. parsed.cmd " " new-fnl-expr)]
                   ;; NOTE: Overriding new fnl cmdline should be apart from the
                   ;; `new-fnl-code`, which could also include additional
                   ;; buffer lines due to the range support.
                   (edit-cmd-history! new-cmdline cmd-history-opts)))))
          (vim.schedule)))))

{: parse-cmd-buf-args
 : parse-cmd-file-args
 : mk-fennel-wrapper-command-callback}
