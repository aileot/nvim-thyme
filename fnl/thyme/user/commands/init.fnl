(import-macros {: when-not : str? : dec : inc : first : command!} :thyme.macros)

(local Path (require :thyme.utils.path))

(local {: lua-cache-prefix : config-filename : config-path}
       (require :thyme.const))

(local {: directory?} (require :thyme.utils.fs))

(local Messenger (require :thyme.utils.messenger))
(local UninstallCommandMessenger (Messenger.new "command/uninstall"))

(local cache-commands (require :thyme.user.commands.cache))
(local rollback-commands (require :thyme.user.commands.rollback))
(local fennel-wrapper-commands (require :thyme.user.commands.fennel))

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

(fn assert-is-file-of-thyme [path]
  (let [sep (or (path:match "/") "\\")]
    (assert (or (= (.. sep :thyme) (path:sub -6))
                (path:find (.. sep :thyme sep) 1 true))
            (.. path " does not belong to thyme"))
    path))

(fn define-commands! [?opts]
  "Define user commands.
@param opts.compiler-options table? (default: same values as main config)
@param opts.cmd-history-opts CmdHistoryOpts? (default: {:method :overwrite :trailing-parens :omit}"
  (command! :ThymeConfigOpen
    {:desc (.. "[thyme] open the main config file " config-filename)}
    (fn []
      (vim.cmd (.. "edit " config-path))))
  (command! :ThymeUninstall
    {:desc "[thyme] delete all the thyme's cache, state, and data files"}
    (fn []
      (case (vim.fn.confirm "Delete all the thyme's cache, state, and data files? It will NOT modify your config files."
                            "&No\n&yes" 1 :Warning)
        2 (let [files [lua-cache-prefix
                       (Path.join (vim.fn.stdpath :cache) :thyme)
                       (Path.join (vim.fn.stdpath :state) :thyme)
                       (Path.join (vim.fn.stdpath :data) :thyme)]]
            (case (vim.secure.trust {:action "remove" :path config-path})
              ;; TODO: Should notify error? but ignore error when
              ;; `.nvim-thyme.fnl` is not trusted yet.
              true
              (UninstallCommandMessenger:notify! "successfully untrust .nvim-thyme.fnl"))
            (each [_ path (ipairs files)]
              (assert-is-file-of-thyme path)
              (when (directory? path)
                (case (vim.fn.delete path :rf)
                  0 (UninstallCommandMessenger:notify! (.. "successfully deleted "
                                                           path))
                  _ (error (.. "failed to delete " path)))))
            (UninstallCommandMessenger:notify! (.. "successfully uninstalled")))
        _ (UninstallCommandMessenger:notify! "aborted"))))
  (cache-commands.setup!)
  (rollback-commands.setup!)
  (fennel-wrapper-commands.setup! ?opts))

{: define-commands!}
