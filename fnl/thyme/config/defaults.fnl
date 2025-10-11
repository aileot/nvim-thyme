(local std-config (vim.fn.stdpath :config))
(local std-fnl-dir? (vim.uv.fs_stat (vim.fs.joinpath std-config "fnl")))
(local use-lua-dir? (not std-fnl-dir?))

{:max-rollbacks 5
 :compiler-options {}
 :fnl-dir (if use-lua-dir? "lua" "fnl")
 ;; Set to fennel.macro-path for macro modules.
 :macro-path (-> ["./fnl/?.fnlm"
                  "./fnl/?/init.fnlm"
                  "./fnl/?.fnl"
                  "./fnl/?/init-macros.fnl"
                  "./fnl/?/init.fnl"
                  ;; NOTE: Only the last items can be `nil`s without errors.
                  (when use-lua-dir? (.. std-config "/lua/?.fnlm"))
                  (when use-lua-dir? (.. std-config "/lua/?/init.fnlm"))
                  (when use-lua-dir? (.. std-config "/lua/?.fnl"))
                  (when use-lua-dir?
                    (.. std-config "/lua/?/init-macros.fnl"))
                  (when use-lua-dir? (.. std-config "/lua/?/init.fnl"))]
                 (table.concat ";"))
 ;; (experimental)
 ;; What args should be passed to the callback?
 :preproc #$
 :notifier vim.notify
 ;; Since the highlighting output rendering are unstable on the
 ;; experimental vim._extui feature on the nvim v0.12.0 nightly, you can
 ;; disable treesitter highlights and make nvim-thyme return plain text
 ;; outputs instead on the keymap and command features.
 :disable-treesitter-highlights false
 :command {:compiler-options false
           :cmd-history {:method "overwrite" :trailing-parens "omit"}
           :Fnl {;; (experimental)
                 :default-range 0}
           :FnlCompile {;; (experimental)
                        :default-range 0}}
 :keymap {:compiler-options false :mappings {}}
 :watch {:event [:BufWritePost :FileChangedShellPost]
         :pattern "*.{fnl,fnlm}"
         ;; TODO: Add :strategy recommended value to
         ;; .nvim-thyme.fnl.example.
         :strategy "clear-all"
         :macro-strategy "clear-all"}
 ;; (experimental)
 ;; TODO: Set the default keys once stable a bit.
 :dropin {:cmdline {:enter-key false :completion-key false}
          :cmdwin {:enter-key false}}}
