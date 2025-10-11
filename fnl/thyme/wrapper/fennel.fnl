(local fennel (require :fennel))

(local {: apply-parinfer} (require :thyme.wrapper.parinfer))
(local {: assert-is-fnl-file : read-file : write-lua-file!}
       (require :thyme.util.fs))

(local {: config-file? &as Config} (require :thyme.lazy-config))

(fn fnl-code->fennel-ready [fnl-code ?opts]
  "Convert `fnl-code` ready to execute on fennel interface.
@param fnl-code string
@param ?opts table WIP
@return string modified fnl-code
@return table fennel compiler options"
  (let [compiler-options (or ?opts Config.compiler-options)
        balanced?-fnl-code (if vim.g.parinfer_loaded
                               (apply-parinfer fnl-code)
                               fnl-code)]
    (when (= nil compiler-options.filename)
      ;; NOTE: fennel.eval resets .filename to nil at the end.
      ;; Ref: src/fennel.fnl @60
      (set compiler-options.filename :fennel-in-thyme))
    (values balanced?-fnl-code compiler-options)))

;; NOTE: Do not carelessly wrap with xpcall.

(fn view [fnl-code ?opts]
  "Evaluate `(fennel.view fnl-code)` on &rtp.
@param fnl-code string?
@param ?opts table? otherwise, main-config's compiler-options are applied.
@return any"
  ;; TODO: Add an interface to `(require-macros <optional>)` at runtime.
  ;; NOTE: Make sure to insert macro searcher.
  (let [(new-fnl-code compiler-options) (fnl-code->fennel-ready fnl-code ?opts)]
    (fennel.view new-fnl-code compiler-options)))

(fn eval [fnl-code ?opts]
  "Evaluate `fnl-code` on &rtp.
@param fnl-code string?
@param ?opts table? otherwise, main-config's compiler-options are applied.
@return any"
  ;; TODO: Add an interface to `(require-macros <optional>)` at runtime.
  ;; NOTE: Make sure to insert macro searcher.
  (let [(new-fnl-code compiler-options) (fnl-code->fennel-ready fnl-code ?opts)]
    (fennel.eval new-fnl-code compiler-options)))

(fn eval-compiler* [fnl-code ?opts]
  "Evaluate `(eval-compiler fnl-code)` on &rtp.
@param fnl-code string?
@param ?opts table? otherwise, main-config's compiler-options are applied.
@return any"
  ;; TODO: Add an interface to `(require-macros <optional>)` at runtime.
  ;; NOTE: Make sure to insert macro searcher.
  (-> (.. "(eval-compiler " fnl-code ")")
      (eval ?opts)))

(fn macrodebug* [fnl-code ?opts]
  "Evaluate `(macrodebug fnl-code)` on &rtp.
@param fnl-code string?
@param ?opts table? otherwise, main-config's compiler-options are applied.
@return any"
  ;; TODO: Add an interface to `(require-macros <optional>)` at runtime.
  ;; NOTE: Make sure to insert macro searcher.
  (-> (.. "(macrodebug " fnl-code ")")
      (eval ?opts)))

(fn compile-string [fnl-code ?opts]
  "Compile `fnl-code` into a lua string on &rtp in memory to return it.
@param fnl-code string?
@param ?opts table? otherwise, main-config's compiler-options are applied.
@return string the compiled lua code"
  ;; TODO: Add an interface to `(require-macros <optional>)` at runtime.
  ;; NOTE: Make sure to insert macro searcher.
  (let [(new-fnl-code compiler-options) (fnl-code->fennel-ready fnl-code ?opts)]
    (fennel.compile-string new-fnl-code compiler-options)))

(fn compile-buf [bufnr ?opts]
  "Compile buf of `bufnr` into lua string lines.
It does not affect file system.
@param bufnr number
@return string compiled lua code"
  ;; NOTE: Do not by-pass parinfer completion just in case.
  (assert-is-fnl-file bufnr)
  (let [buf-lines (vim.api.nvim_buf_get_lines bufnr 0 -1 true)
        (new-fnl-code compiler-options) (fnl-code->fennel-ready buf-lines ?opts)
        buf-name (vim.api.nvim_buf_get_name bufnr)]
    (set compiler-options.filename buf-name)
    (fennel.compile-string new-fnl-code compiler-options)))

(fn compile-file [fnl-path ?opts]
  "Compile `fnl-path` into lua string lines. It does not affect file system.
@param fnl-path string
@return string compiled lua code"
  ;; NOTE: Do not by-pass parinfer completion just in case.
  (assert-is-fnl-file fnl-path)
  (let [fennel (require :fennel)
        compiler-options (or ?opts Config.compiler-options)
        fnl-lines (read-file fnl-path)]
    (set compiler-options.filename fnl-path)
    (fennel.compile-string fnl-lines compiler-options)))

(fn compile-file! [fnl-path lua-path ?opts]
  "Compile `fnl-path` into a lua file at `lua-path`.
@param fnl-path string
@param lua-path string
@param ?opts table fennel's compiler option"
  (assert (not (config-file? fnl-path))
          "abort. attempted to compile config file")
  (let [lua-lines (compile-file fnl-path ?opts)]
    (assert (load lua-lines))
    (write-lua-file! lua-path lua-lines)))

{: view
 : eval
 :eval-compiler eval-compiler*
 :macrodebug macrodebug*
 : compile-string
 : compile-buf
 : compile-file
 : compile-file!}
