(import-macros {: when-not : str? : dec : inc : first : command!} :thyme.macros)

(local fennel (require :fennel))

(local tts (require :thyme.wrapper.treesitter))

(local {: apply-parinfer} (require :thyme.wrapper.parinfer))

(local {: lua-cache-prefix} (require :thyme.const))

(local {: file-readable? : read-file : write-lua-file!}
       (require :thyme.utils.fs))

(local Messenger (require :thyme.utils.messenger))
(local CommandMessenger (Messenger.new "command/fennel"))

(local {: config-file? &as Config} (require :thyme.config))

(local {: fnl-path->lua-path} (require :thyme.module-map.logger))

(local fennel-wrapper (require :thyme.wrapper.fennel))

(local M {})

(fn edit-cmd-history! [new-fnl-code opts]
  "Edit Vim command history with `new-fnl-code`.
@param new-fnl-code string expecting a fnl code balanced by parinfer
@param opts.method 'overwrite'|'append'|'ignore'
@param opts.trailing-parens 'omit'|'keep'"
  (let [make-new-cmd (fn [new-fnl-code]
                       (let [trimmed-new-fnl-code (new-fnl-code:gsub "%s*[%]}%)]*$"
                                                                     "")
                             last-cmd (vim.fn.histget ":" -1)]
                         (case (last-cmd:find trimmed-new-fnl-code 1 true)
                           (idx-start idx-end) (let [prefix (-> last-cmd
                                                                (: :sub 1
                                                                   (dec idx-start)))
                                                     suffix (-> new-fnl-code
                                                                (: :gsub "%s*$"
                                                                   "")
                                                                (: :sub
                                                                   (- idx-end
                                                                      idx-start
                                                                      -2)))
                                                     trimmed-suffix (case opts.trailing-parens
                                                                      :omit (suffix:gsub "^[%]}%)]*"
                                                                                         "")
                                                                      :keep suffix
                                                                      ?val
                                                                      (error (.. "expected one of `omit` or `keep`; got unknown value for trailing-parens: "
                                                                                 (vim.inspect ?val))))
                                                     new-cmd (.. prefix
                                                                 trimmed-new-fnl-code
                                                                 trimmed-suffix)]
                                                 new-cmd))))
        methods {:overwrite (fn [new-cmd]
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
    (case (. methods opts.method)
      apply-method (let [new-cmd (make-new-cmd new-fnl-code)]
                     (apply-method new-cmd))
      _
      (error (.. "expected one of `overwrite`, `append`, or `ignore`; got unknown method "
                 opts.method)))))

(fn wrap-fennel-wrapper-for-command [callback
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
                           (apply-parinfer {: cmd-history-opts}))]
      (when verbose?
        ;; TODO: Replace with nvim_echo on treesitter highlight?
        (tts.print ";;; Source")
        (tts.print new-fnl-code)
        (tts.print ";;; Result"))
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
        (-> #(edit-cmd-history! new-fnl-code cmd-history-opts)
            (vim.schedule))))))

(fn open-buffer! [buf|path {: split : tab &as mods}]
  "Open buffer as `mods.split` value.
@param buf|path number|string buffer-number or path
@param mods table
@param mods.split string"
  (let [split? (or (not= -1 tab) (not= "" split))
        cmd (case (type buf|path)
              :number (if split? :sbuffer :buffer)
              :string (if split? :split :edit))]
    (vim.cmd {: cmd :args [buf|path] : mods})))

(fn M.setup! [?opts]
  "Define fennel wrapper commands.
@param ?opts.fnl-cmd-prefix string (default: \"Fnl\")
@param ?opts.compiler-options table? (default: same values as main config)
@param ?opts.cmd-history-opts CmdHistoryOpts? (default: {:method :overwrite :trailing-parens :omit}"
  (let [opts (if ?opts
                 (vim.tbl_deep_extend :force Config.command ?opts)
                 Config.command)
        fnl-cmd-prefix opts.fnl-cmd-prefix
        compiler-options opts.compiler-options
        cmd-history-opts opts.cmd-history]
    (when-not (= "" fnl-cmd-prefix)
      (command! fnl-cmd-prefix
        {:nargs "*"
         :complete :lua
         :desc "[thyme] evaluate the following fennel expression, and display the results"}
        (wrap-fennel-wrapper-for-command fennel-wrapper.eval
                                         {:lang :fennel
                                          : compiler-options
                                          : cmd-history-opts})))
    (command! (.. fnl-cmd-prefix :Eval)
      {:nargs "*"
       :complete :lua
       :desc "[thyme] evaluate the following fennel expression, and display the results"}
      (wrap-fennel-wrapper-for-command fennel-wrapper.eval
                                       {:lang :fennel
                                        : compiler-options
                                        : cmd-history-opts}))
    (command! (.. fnl-cmd-prefix :CompileString)
      {:nargs "*"
       :desc "[thyme] display the compiled lua results of the following fennel expression"}
      (wrap-fennel-wrapper-for-command fennel-wrapper.compile-string
                                       {:lang :lua
                                        :discard-last? true
                                        : compiler-options
                                        : cmd-history-opts}))
    (command! (.. fnl-cmd-prefix :EvalFile)
      {:range "%"
       :nargs "?"
       :complete :file
       :desc "[thyme] evaluate given file, or current file, and display the results"}
      (fn [{:fargs [?path] : line1 : line2 &as a}]
        (let [fnl-code (let [full-path (-> (or ?path "%:p")
                                           (vim.fn.expand)
                                           (vim.fn.fnamemodify ":p"))]
                         ;; NOTE: fs.read-file returns the contents in
                         ;; a string while vim.fn.readfile returns in
                         ;; a list.
                         (-> (vim.fn.readfile full-path "" line2)
                             (vim.list_slice line1)
                             (table.concat "\n")))
              callback (wrap-fennel-wrapper-for-command fennel-wrapper.eval
                                                        {:lang :fennel
                                                         : compiler-options
                                                         : cmd-history-opts})]
          (set a.args fnl-code)
          (callback a))))
    (command! (.. fnl-cmd-prefix :EvalBuffer)
      {:range "%"
       :nargs "?"
       :complete :buffer
       :desc "[thyme] evaluate given buffer, or current buffer, and display the results"}
      (fn [{:fargs [?path] : line1 : line2 &as a}]
        (let [fnl-code (let [bufnr (if ?path (vim.fn.bufnr ?path) 0)]
                         (-> (vim.api.nvim_buf_get_lines bufnr (dec line1)
                                                         line2 true)
                             (table.concat "\n")))
              callback (wrap-fennel-wrapper-for-command fennel-wrapper.eval
                                                        {:lang :fennel
                                                         : compiler-options
                                                         : cmd-history-opts})]
          (set a.args fnl-code)
          (callback a))))
    (command! (.. fnl-cmd-prefix :CompileBuffer)
      {:range "%"
       :nargs "?"
       :complete :buffer
       :desc "[thyme] display the compiled lua results of current buffer"}
      (fn [{:fargs [?path] : line1 : line2 &as a}]
        (let [fnl-code (let [bufnr (if ?path (vim.fn.bufnr ?path) 0)]
                         (-> (vim.api.nvim_buf_get_lines bufnr (dec line1)
                                                         line2 true)
                             (table.concat "\n")))
              callback (wrap-fennel-wrapper-for-command fennel-wrapper.compile-string
                                                        {:lang :lua
                                                         :discard-last? true
                                                         : compiler-options
                                                         : cmd-history-opts})]
          (set a.args fnl-code)
          (callback a))))
    ;; (command! (.. fnl-cmd-prefix :ReplOnRtp)
    ;;   {:nargs "*" :desc "WIP: Start REPL in thyme"}
    ;;   (fn [a]
    ;;     "Start REPL in thyme.
    ;;     @param opts.emulate boolean (default: true)
    ;;     @param opts.buf-opts table
    ;;     @param opts.buf-opts.buflisted boolean (default: true)"
    ;;     ;; WIP
    ;;     (let [opts {:mods a.smods :floating false :emulate true}
    ;;           buflisted? (or (?. opts.buf-opts :buflisted) true)
    ;;           scratch? true
    ;;           floating-window? opts.floating
    ;;           buf (vim.api.nvim_create_buf buflisted? scratch?)
    ;;           ;; TODO: deep-merge win-opts.
    ;;           win-opts (or opts.win-opts {:title "REPL in thyme"})]
    ;;       (if floating-window?
    ;;           (vim.api.nvim_open_win buf true win-opts)
    ;;           (open-buffer! buf opts.mods)))))
    (command! (.. fnl-cmd-prefix :CompileFile)
      {:nargs "*"
       :bang true
       :complete :file
       :desc "Compile given fnl files, or current fnl buffer"}
      ;; NOTE: mods.confirm to confirm any files; without `bang` to confirm to
      ;; overwrite existing file.
      (fn [{:fargs glob-paths :bang force-compile?}]
        (let [fnl-paths (if (= 0 (length glob-paths))
                            [(vim.api.nvim_buf_get_name 0)]
                            (-> (icollect [_ path (ipairs glob-paths)]
                                  (-> (vim.fn.glob path)
                                      (vim.split "\n")))
                                (vim.fn.flatten 1)))
              path-pairs (collect [_ path (ipairs fnl-paths)]
                           (let [full-path (vim.fn.fnamemodify path ":p")]
                             (values full-path (fnl-path->lua-path full-path))))
              existing-lua-files []]
          (when (or force-compile?
                    (and (icollect [_ lua-file (pairs path-pairs)]
                           ;; HACK: icollect always returns truthy.
                           (when (file-readable? lua-file)
                             (table.insert existing-lua-files lua-file)))
                         (if (< 0 (length existing-lua-files))
                             (case (-> (.. "The following files have already existed:
    " ;
                                           (table.concat existing-lua-files
                                                         "\n")
                                           "\nOverride the files?")
                                       (vim.fn.confirm "&No\n&yes"))
                               2 true
                               _ (do
                                   (CommandMessenger:notify! :Abort)
                                   ;; NOTE: Just in case, thought vim.notify returns nil.
                                   false)))))
            (let [;; TODO: Add interface to overwrite fennel-options in this
                  ;; command?
                  fennel-options Config.compiler-options]
              (each [fnl-path lua-path (pairs path-pairs)]
                (assert (not (config-file? fnl-path))
                        "Abort. Attempted to compile config file")
                (let [lua-lines (fennel-wrapper.compile-file fnl-path
                                                             fennel-options)]
                  (if (= lua-lines (read-file lua-path))
                      (CommandMessenger:notify! (.. "Abort. Nothing has changed in "
                                                    fnl-path))
                      (let [msg (.. fnl-path " is compiled into " lua-path)]
                        ;; TODO: Remove dependent files.
                        (write-lua-file! lua-path lua-lines)
                        (CommandMessenger:notify! msg))))))))))
    (command! (.. fnl-cmd-prefix :Alternate)
      ;; TODO: Alternate lua-file to fennel-file.
      {:nargs "?" :complete :file :desc "[thyme] alternate fnl<->lua"}
      (fn [{:fargs [?path] :smods mods}]
        (let [input-path (vim.fn.expand (or ?path "%:p"))
              output-path (case (input-path:sub -4)
                            :.fnl (case (fnl-path->lua-path input-path)
                                    lua-path
                                    lua-path
                                    _
                                    ;; For generaric cases.
                                    (case (.. (input-path:sub 1 -4) :lua)
                                      lua-path (if (file-readable? lua-path)
                                                   lua-path
                                                   (lua-path:gsub :/fnl/ :/lua/))))
                            :.lua (if (vim.startswith input-path
                                                      lua-cache-prefix)
                                      (-> (input-path:sub (length lua-cache-prefix))
                                          (: :gsub "%.lua$" :.fnl)
                                          (: :gsub "^" "*")
                                          (vim.api.nvim_get_runtime_file false)
                                          (first))
                                      ;; TODO: Is it worth considering more
                                      ;; complicated settings in .nvim-thyme.fnl?
                                      (-> input-path
                                          (: :gsub :/lua/ "/*/")
                                          (: :gsub "%.lua$" :.fnl)
                                          (vim.fn.glob false)))
                            _ (error "expected a fnl or lua file, got"
                                     input-path))]
          ;; TODO: Set smods.noswapfile=true?
          (if (file-readable? output-path)
              (open-buffer! output-path mods)
              (when-not mods.emsg_silent
                (-> (.. "failed to find the alternate file of " input-path)
                    (CommandMessenger:notify! vim.log.levels.WARN)))))))))

M
