(import-macros {: when-not : dec : first : command!} :thyme.macros)

(local {: lua-cache-prefix} (require :thyme.const))

(local {: file-readable?} (require :thyme.util.fs))

(local Messenger (require :thyme.util.class.messenger))
(local CommandMessenger (Messenger.new "command/fennel"))

(local Config (require :thyme.config))

(local DependencyLogger (require :thyme.dependency.logger))

(local fennel-wrapper (require :thyme.wrapper.fennel))

(local {: parse-cmd-buf-args
        : parse-cmd-file-args
        : mk-fennel-wrapper-command-callback}
       (require :thyme.user.command.fennel.fennel-wrapper))

(local fnl-file-compile (require :thyme.user.command.fennel.fnl-file-compile))

(local M {})

(fn open-buf! [buf|path {: split : tab &as mods}]
  "Open buf as `mods.split` value.
@param buf|path number|string buffer-number or path
@param mods table
@param mods.split string"
  (let [split? (or (not= -1 tab) (not= "" split))
        cmd (case (type buf|path)
              :number (if split? :sbuffer :buffer)
              :string (if split? :split :edit))]
    (vim.cmd {: cmd :args [buf|path] : mods})))

(fn M.setup! []
  "Define fennel wrapper commands."
  (let [compiler-options (or Config.command.compiler-options
                             Config.compiler-options)
        cmd-history-opts Config.command.cmd-history]
    (fnl-file-compile.create-commands!)
    (command! :Fnl
      {:range "%"
       :nargs "+"
       :complete "lua"
       :desc "[thyme] evaluate the following fennel expression, and display the results"}
      (mk-fennel-wrapper-command-callback fennel-wrapper.eval
                                          {:lang :fennel
                                           : compiler-options
                                           : cmd-history-opts}))
    (command! :FnlBuf
      {:range "%"
       :nargs "?"
       :complete "buffer"
       :desc "[thyme] evaluate given buffer, or current buffer, and display the results"}
      (fn [a]
        (let [fnl-code (parse-cmd-buf-args a)
              cmd-history-opts {:method :ignore}
              callback (mk-fennel-wrapper-command-callback fennel-wrapper.eval
                                                           {:lang :fennel
                                                            : compiler-options
                                                            : cmd-history-opts})]
          (set a.args fnl-code)
          (callback a))))
    (command! :FnlFile
      {:range "%"
       :nargs "?"
       :complete "file"
       :desc "[thyme] evaluate given file, or current file, and display the results"}
      (fn [a]
        (let [fnl-code (parse-cmd-file-args a)
              cmd-history-opts {:method :ignore}
              callback (mk-fennel-wrapper-command-callback fennel-wrapper.eval
                                                           {:lang :fennel
                                                            : compiler-options
                                                            : cmd-history-opts})]
          (set a.args fnl-code)
          (callback a))))
    (command! :FnlCompile
      {:range "%"
       :nargs "+"
       :complete "lua"
       :desc "[thyme] display the compiled lua results of the following fennel expression"}
      (mk-fennel-wrapper-command-callback fennel-wrapper.compile-string
                                          {:lang :lua
                                           : compiler-options
                                           : cmd-history-opts}))
    (let [cb (fn [a]
               (let [fnl-code (parse-cmd-buf-args a)
                     cmd-history-opts {:method :ignore}
                     callback (mk-fennel-wrapper-command-callback fennel-wrapper.compile-string
                                                                  {:lang :lua
                                                                   : compiler-options
                                                                   : cmd-history-opts})]
                 (set a.args fnl-code)
                 (callback a)))
          cmd-opts {:range "%"
                    :nargs "?"
                    :complete "buffer"
                    :desc "[thyme] display the compiled lua results of given buffer, or current buffer as fennel expression"}]
      (command! :FnlBufCompile
        cmd-opts
        cb)
      (command! :FnlCompileBuf
        cmd-opts
        cb))
    ;; NOTE: mods.confirm to confirm any files; without `bang` to confirm to
    ;; overwrite existing file.
    ;; (command! :FnlReplOnRtp)
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
    ;;           (open-buf! buf opts.mods)))))
    (command! :FnlAlternate
      ;; TODO: Alternate lua-file to fennel-file.
      {:nargs "?" :complete "file" :desc "[thyme] alternate fnl<->lua"}
      (fn [{:fargs [?path] :smods mods}]
        (let [input-path (vim.fn.expand (or ?path "%:p"))
              output-path (case (input-path:sub -4)
                            :.fnl (case (DependencyLogger:fnl-path->lua-path input-path)
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
              (open-buf! output-path mods)
              (when-not mods.emsg_silent
                (-> (.. "failed to find the alternate file of " input-path)
                    (CommandMessenger:notify! vim.log.levels.WARN)))))))))

M
