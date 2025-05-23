;; Example options for nvim-thyme; some of the values are different from the default ones.

(let [std-config (vim.fn.stdpath :config)
      std-fnl-dir? (vim.uv.fs_stat (vim.fs.joinpath std-config "fnl"))
      use-lua-dir? (not std-fnl-dir?)]
  {:compiler-options {:correlate true
                      ;; Comment out below to enable `vim` APIs and any others in
                      ;; compile time.
                      ;; :compilerEnv _G
                      ;; Emphasize the error position with the pair of the strings.
                      :error-pinpoint ["|>>" "<<|"]}
   ;; The directory relative to `(stdpath :config)` to manage your Fennel modules
   ;; like you manage Lua modules under lua/. The value only affects non-macro
   ;; modules; for Fennel macros, arrange `macro-path` option instead.
   :fnl-dir (if use-lua-dir? "lua" "fnl")
   ;; The path patterns for `fennel.macro-path` to find Fennel macro module
   ;; path. Relative path markers (`.`) are internally replaced with the paths on
   ;; &runtimepath filtered by the directories preceded by `?`, for example, in
   ;; `./fnl/?.fnl`.
   :macro-path (-> ["./fnl/?.fnlm"
                    "./fnl/?/init.fnlm"
                    "./fnl/?.fnl"
                    "./fnl/?/init-macros.fnl"
                    "./fnl/?/init.fnl"
                    ;; NOTE: Only the last items can be `nil`s without errors.
                    (when use-lua-dir? (.. std-config "/lua/?.fnlm"))
                    (when use-lua-dir? (.. std-config "/lua/?/init.fnlm"))
                    (when use-lua-dir? (.. std-config "/lua/?.fnl"))
                    (when use-lua-dir? (.. std-config "/lua/?/init.fnl"))]
                   (table.concat ";"))
   :max-rollbacks 5
   :notifier (fn [msg ...]
               (let [noisy-notifier (or (case (pcall require :fidget)
                                          (true mod) mod.notify)
                                        (case (pcall require :noice)
                                          (true mod) mod.notify)
                                        (case (pcall require :notify)
                                          (true mod) mod.notify)
                                        (case (pcall require :mini.notify)
                                          (true mod) (mod.make_notify))
                                        vim.notify)]
                 ;; Extract scope
                 (case (msg:match "^thyme%((.-)%): ")
                   "autocmd/watch"
                   (noisy-notifier msg ...)
                   ;; You can suppress messages of specific scopes.
                   ;; scope (if (vim.endswith scope "rollback/mounted") nil
                   ;;           (vim.notify msg ...))
                   _
                   (vim.notify msg ...))))
   :command {;; Set it to nil to inherit the values from the root option.
             :compiler-options {:correlate false :error-pinpoint ["|>>" "<<|"]}
             :cmd-history {;; With parinfer integration and the options below,
                           ;; nvim-thyme will modify your command history with
                           ;; parinfer-ed command results for fennel wrapper
                           ;; Ex commands.
                           ;; "overwrite"|"append"|"ignore"
                           :method "overwrite"
                           ;; trailing-parens only affects command history when
                           ;; the method option is set to either "overwrite" or
                           ;; "append".
                           ;; "omit"|"keep"
                           :trailing-parens "omit"}}
   :keymap {:compiler-options {:correlate false :error-pinpoint ["|>>" "<<|"]}
            ;; NOTE: "x" for Visual mode. See `:mapmode-x` for more details.
            ;; NOTE: You can map the same keys for both normal and visual modes
            ;; in a sequential table `[:n :x]` as `vim.keymap.set` does.
            :mappings {[:n :x] {:alternate-file "<LocalLeader>a"
                                :operator-echo-compile-string "<LocalLeader>s"
                                :operator-echo-eval "<LocalLeader>e"
                                :operator-echo-eval-compiler "<LocalLeader>c"
                                :operator-echo-macrodebug "<LocalLeader>m"}}
            ;; NOTE: You can map different operator keymaps between normal mode
            ;; and visual mode.
            :mappings {;; NOTE: "echo" versions will not add the outputs to the
                       ;; command history.
                       :n {:alternate-file "<LocalLeader>a"
                           :operator-echo-compile-string "<LocalLeader>s"
                           :operator-echo-eval "<LocalLeader>e"
                           :operator-echo-eval-compiler "<LocalLeader>c"
                           :operator-echo-macrodebug "<LocalLeader>m"}
                       ;; NOTE: "print" versions will add the outputs to the
                       ;; command history.
                       :x {:alternate-file "<LocalLeader>a"
                           :operator-print-compile-string "<LocalLeader>s"
                           :operator-print-eval "<LocalLeader>e"
                           :operator-print-eval-compiler "<LocalLeader>c"
                           :operator-print-macrodebug "<LocalLeader>m"}}}
   :watch {:event [:BufWritePost :FileChangedShellPost]
           :pattern "*.{fnl,fnlm}"
           ;; NOTE: Available Strategies:
           ;; - "clear-all": clear all the Lua caches by nvim-thyme
           ;; - "clear": clear the cache of the module and its dependencies
           ;; - "recompile": recompile the module and its dependencies
           :strategy "recompile"
           :macro-strategy "clear-all"}})
