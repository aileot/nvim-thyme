(import-macros {: when-not : str? : dec : first} :thyme.macros)

(local tts (require :thyme.wrapper.treesitter))

(local {: lua-cache-prefix : config-filename : config-path}
       (require :thyme.const))

(local {: get-main-config : config-file?} (require :thyme.config))

(local {: file-readable? : read-file : write-lua-file!}
       (require :thyme.utils.fs))

(local fennel-wrapper (require :thyme.wrapper.fennel))
(local {: apply-parinfer} (require :thyme.wrapper.parinfer))
(local {: clear-cache!} (require :thyme.compiler.cache))
(local {: fnl-path->lua-path} (require :thyme.module-map.logger))

(local fennel (require :fennel))

(macro command! [name opts callback]
  `(vim.api.nvim_create_user_command ,name ,callback ,opts))

;; (fn get-candidates-in-cache-dir [arg-lead _cmdline _cursorpos]
;;   "Return list of directories under thyme's cache as `arg-lead`.
;; @param arg-lead string
;; @return string[]"
;;   (let [root lua-cache-prefix
;;         current-path (Path.join root arg-lead)
;;         glob-result (vim.fn.glob (.. current-path "*"))]
;;     (-> (if (current-path:find (.. "^" glob-result Path.sep "?$"))
;;             (vim.fn.glob (Path.join current-path "*"))
;;             glob-result)
;;         (: :gsub (.. root Path.sep) "")
;;         (vim.split "\n"))))

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

(fn wrap-fennel-wrapper-for-command [callback
                                     {: lang
                                      : discard-last?
                                      : compiler-options
                                      : overwrite-cmd-history?
                                      : omit-trailing-parens?}]
  "Wrap the `fennel` wrapper callback of thyme.
@param callback fun(fnl-code: string): any
@param opts.lang string? (default: \"fennel\")
@param opts.compiler-options table? (default: same values as main config)
@param opts.overwrite-cmd-history? bool? (default: true)
@param opts.omit-trailing-parens? bool? (default: true)"
  (fn [{: args : smods}]
    (let [verbose? (< -1 smods.verbose)
          new-fnl-code (-> args
                           (apply-parinfer {: overwrite-cmd-history?
                                            : omit-trailing-parens?}))]
      (when verbose?
        ;; TODO: Replace with nvim_echo on treesitter highlight?
        (tts.print ";;; Source")
        (tts.print new-fnl-code)
        (tts.print ";;; Result"))
      (let [results [(callback new-fnl-code compiler-options)]]
        (case (length results)
          0 (tts.print :nil {: lang})
          last-idx (each [i ?text (ipairs results) ;
                          ;; Note: Some function like fennel.compile-string returns
                          ;; additional table at last. That is usually unintended
                          ;; information for users.
                          &until (and discard-last? (<= last-idx i))]
                     (let [text (if (= lang :lua) ?text ;
                                    (fennel.view ?text compiler-options))]
                       (tts.print text {: lang}))))))))

(fn define-commands! [?opts]
  "Define user commands.
@param opts.compiler-options table? (default: same values as main config)
@param opts.overwrite-cmd-history? bool? (default: true)
@param opts.omit-trailing-parens? bool? (default: true)"
  (let [opts (or ?opts {})
        cmd-prefix (or opts.cmd-prefix :Fnl)
        compiler-options opts.compiler-options
        overwrite-cmd-history? (or opts.overwrite-cmd-history? true)
        omit-trailing-parens? (or opts.omit-trailing-parens? true)]
    (when-not (= "" cmd-prefix)
      (command! cmd-prefix
        {:nargs "*"
         :complete :lua
         :desc "[thyme] evaluate the following fennel expression, and display the results"}
        (wrap-fennel-wrapper-for-command fennel-wrapper.eval
                                         {:lang :fennel
                                          : compiler-options
                                          : overwrite-cmd-history?
                                          : omit-trailing-parens?})))
    (command! (.. cmd-prefix :Eval)
      {:nargs "*"
       :complete :lua
       :desc "[thyme] evaluate the following fennel expression, and display the results"}
      (wrap-fennel-wrapper-for-command fennel-wrapper.eval
                                       {:lang :fennel
                                        : compiler-options
                                        : overwrite-cmd-history?
                                        : omit-trailing-parens?}))
    (command! (.. cmd-prefix :CompileString)
      {:nargs "*"
       :desc "[thyme] display the compiled lua results of the following fennel expression"}
      (wrap-fennel-wrapper-for-command fennel-wrapper.compile-string
                                       {:lang :lua
                                        :discard-last? true
                                        : compiler-options
                                        : overwrite-cmd-history?
                                        : omit-trailing-parens?}))
    (command! (.. cmd-prefix :EvalFile)
      {:range "%"
       :nargs "?"
       :complete :file
       :desc "[thyme] evaluate given file, or current file, and display the results"}
      (fn [{:fargs [?path] : line1 : line2 &as a}]
        (let [fnl-code (let [full-path (-> (or ?path "%:p")
                                           (vim.fn.expand)
                                           (vim.fn.fnamemodify ":p"))]
                         ;; Note: fs.read-file returns the contents in
                         ;; a string while vim.fn.readfile returns in
                         ;; a list.
                         (-> (vim.fn.readfile full-path "" line2)
                             (vim.list_slice line1)
                             (table.concat "\n")))
              callback (wrap-fennel-wrapper-for-command fennel-wrapper.eval
                                                        {:lang :fennel
                                                         : compiler-options
                                                         : overwrite-cmd-history?
                                                         : omit-trailing-parens?})]
          (set a.args fnl-code)
          (callback a))))
    (command! (.. cmd-prefix :EvalBuffer)
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
                                                         : overwrite-cmd-history?
                                                         : omit-trailing-parens?})]
          (set a.args fnl-code)
          (callback a))))
    (command! (.. cmd-prefix :CompileBuffer)
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
                                                         : overwrite-cmd-history?
                                                         : omit-trailing-parens?})]
          (set a.args fnl-code)
          (callback a))))
    ;; (command! (.. cmd-prefix :ReplOnRtp)
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
    (command! (.. cmd-prefix :CompileFile)
      {:nargs "*"
       :bang true
       :complete :file
       :desc "Compile given fnl files, or current fnl buffer"}
      ;; Note: mods.confirm to confirm any files; without `bang` to confirm to
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
                                   (vim.notify :Abort)
                                   ;; Note: Just in case, thought vim.notify returns nil.
                                   false)))))
            (let [;; TODO: Add interface to overwrite fennel-options in this
                  ;; command?
                  config (get-main-config)
                  fennel-options config.compiler-options]
              (each [fnl-path lua-path (pairs path-pairs)]
                (assert (not (config-file? fnl-path))
                        "Abort. Attempted to compile config file")
                (let [lua-lines (fennel-wrapper.compile-file fnl-path
                                                             fennel-options)]
                  (if (= lua-lines (read-file lua-path))
                      (vim.notify (.. "Abort. Nothing has changed in " fnl-path))
                      (let [msg (.. fnl-path " is compiled into " lua-path)]
                        ;; TODO: Remove dependent files.
                        (write-lua-file! lua-path lua-lines)
                        (vim.notify msg))))))))))
    (command! :ThymeConfigOpen
      {:desc (.. "[thyme] open the main config file " config-filename)}
      (fn []
        (vim.cmd (.. "tab drop " config-path))))
    (command! (.. cmd-prefix :CacheOpen)
      {:desc "[thyme] open the cache root directory"}
      (fn []
        ;; Note: Filer plugin like oil.nvim usually modifies the buffer name
        ;; so that `:tab drop` is unlikely to work expectedly.
        (vim.cmd (.. "tab drop " lua-cache-prefix))))
    (command! (.. cmd-prefix :CacheClear)
      ;; Note: No args will be allowed because handling module-map would
      ;; be a bit complicated.
      {:bar true
       :bang true
       :desc "[thyme] clear the lua cache and dependency map logs"}
      ;; TODO: Or `:confirm` prefix to ask?
      (fn []
        (if (clear-cache!)
            (vim.notify (.. "Cleared cache: " lua-cache-prefix))
            (vim.notify (.. "No cache files detected at " lua-cache-prefix)))))
    (command! (.. cmd-prefix :Alternate)
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
                    (vim.notify vim.log.levels.WARN)))))))))

{: define-commands!}
