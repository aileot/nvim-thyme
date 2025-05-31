(import-macros {: command!} :thyme.macros)

(local {: file-readable? : read-file : write-lua-file!}
       (require :thyme.util.fs))

(local Messenger (require :thyme.util.class.messenger))
(local CommandMessenger (Messenger.new "command/fennel"))

(local {: config-file? &as Config} (require :thyme.config))

(local DependencyLogger (require :thyme.dependency.logger))

(local fennel-wrapper (require :thyme.wrapper.fennel))

(fn create-commands! []
  (let [cb (fn [{:fargs glob-paths :bang force-compile?}]
             (let [fnl-paths (if (= 0 (length glob-paths))
                                 [(vim.api.nvim_buf_get_name 0)]
                                 (-> (icollect [_ path (ipairs glob-paths)]
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
                                                (table.concat existing-lua-files
                                                              "\n")
                                                "\nOverride the files?")
                                            (vim.fn.confirm "&No\n&yes"))
                                    2 true
                                    _ (do
                                        (CommandMessenger:notify! :Abort)
                                        ;; NOTE: Just in case, thought vim.notify returns nil.
                                        false)))))
                 (let [
                       ;; TODO: Add interface to overwrite fennel-options in this
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
                             (CommandMessenger:notify! msg)))))))))
        cmd-opts {:range "%"
                  :nargs "*"
                  :bang true
                  :complete :file
                  :desc "Compile given fnl files, or current fnl file"}]
    (command! :FnlFileCompile
      cmd-opts
      cb)
    (command! :FnlCompileFile
      cmd-opts
      cb)))

{: create-commands!}
