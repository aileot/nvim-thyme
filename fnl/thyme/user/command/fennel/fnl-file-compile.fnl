(import-macros {: command!} :thyme.macros)

(local {: file-readable? : read-file : write-lua-file!}
       (require :thyme.util.fs))

(local Messenger (require :thyme.util.class.messenger))
(local CommandMessenger (Messenger.new "command/fennel"))

(local {: config-file? &as Config} (require :thyme.config))

(local DependencyLogger (require :thyme.dependency.logger))

(local fennel-wrapper (require :thyme.wrapper.fennel))

(local {: parse-cmd-file-args : mk-fennel-wrapper-command-callback}
       (require :thyme.user.command.fennel.fennel-wrapper))

(fn compile-to-write! [fnl-path force-compile?]
  "Compile the given Fennel file to Lua file, and write it to disk.
@param fnl-path The path to the Fennel file to compile.
@param force-compile? If true, will compile even if the Lua file already exists."
  ;; FIXME: Make it work.
  (let [fnl-paths (if (= 0 (length fnl-path))
                      [(vim.api.nvim_buf_get_name 0)]
                      (-> (icollect [_ path (ipairs fnl-path)]
                            (-> (vim.fn.glob path)
                                (vim.split "\n")))
                          (vim.fn.flatten 1)))
        path-pairs (collect [_ path (ipairs fnl-paths)]
                     (let [full-path (vim.fn.fnamemodify path ":p")]
                       (values full-path
                               (DependencyLogger:fnl-path->lua-path full-path))))
        existing-lua-files []]
    (when (or force-compile?
              (and (icollect [_ lua-file (pairs path-pairs)]
                     ;; HACK: icollect always returns truthy.
                     (when (file-readable? lua-file)
                       (table.insert existing-lua-files lua-file)))
                   (if (< 0 (length existing-lua-files))
                       (case (-> (.. "The following files have already existed:
" ;
                                     (table.concat existing-lua-files "\n")
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
          (let [lua-lines (fennel-wrapper.compile-file fnl-path fennel-options)]
            (if (= lua-lines (read-file lua-path))
                (CommandMessenger:notify! (.. "Abort. Nothing has changed in "
                                              fnl-path))
                (let [msg (.. fnl-path " is compiled into " lua-path)]
                  ;; TODO: Remove dependent files.
                  (write-lua-file! lua-path lua-lines)
                  (CommandMessenger:notify! msg)))))))))

(fn create-commands! []
  (let [compiler-options (or Config.command.compiler-options
                             Config.compiler-options)
        cmd-history-opts {:method "ignore"}
        cb (fn [{: fargs
                 :bang should-write-file?
                 :mods {:confirm confirm?}
                 &as a}]
             (let [fnl-code (parse-cmd-file-args a)
                   [fnl-path] (if (= 0 (length fargs))
                                  [(vim.fn.expand "%:p")]
                                  fargs)]
               (if should-write-file?
                   (compile-to-write! fnl-path (not confirm?))
                   (let [opts {:lang "lua"
                               : compiler-options
                               : cmd-history-opts}
                         callback (mk-fennel-wrapper-command-callback fennel-wrapper.compile-string
                                                                      opts)]
                     (set a.args fnl-code)
                     (callback a)))))
        cmd-opts {:range "%"
                  :nargs "?"
                  ;; TODO: Allow `bang` option to write the compiled lua result to a file.
                  ;; :bang true
                  :complete "file"
                  :desc "[thyme] display compiled lua result of given fnl file, or current fnl file"}]
    (command! :FnlFileCompile
      cmd-opts
      cb)
    (command! :FnlCompileFile
      cmd-opts
      cb)))

{: create-commands!}
