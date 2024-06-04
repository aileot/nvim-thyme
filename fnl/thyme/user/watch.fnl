;;; This is just a autocmd wrapper of thyme.user.check.
;;; It only helps users write shorter than with vim.api.nvim_create_augroup
;;; and vim.api.nvim_create_autocmd.

(local {: check-to-update!} (require :thyme.user.check))

(var ?group nil)

(macro augroup! [...]
  `(vim.api.nvim_create_augroup ,...))

(macro autocmd! [...]
  `(vim.api.nvim_create_autocmd ,...))

(fn watch-to-update! [?opts]
  "Add an autocmd in augroup \"Thyme\" to watch fennel files.
It overrides the previously defined `autocmd`s if both event and pattern are
the same.
@param ?opts.verbose boolean (default: false) notify if successfully compiled file.
@param ?opts.dependent-files 'delete'|'ignore' (default: 'delete')
@param ?opts.live-reload boolean WIP (default: false)
@param ?opts.event string|string[] autocmd-event
@param ?opts.pattern string|string[] autocmd-pattern
@return number autocmd-id"
  (let [group (or ?group (augroup! :ThymeWatch {}))
        opts (or ?opts {})
        ;; TODO: Also consider RemoteReply, ShellCmdPost, etc.?
        event (or opts.event [:BufWritePost :FileChangedShellPost])
        pattern (or opts.pattern :*.fnl)
        callback (fn [{:match fnl-path}]
                   (check-to-update! fnl-path opts)
                   ;; Prevent not to destroy the autocmd.
                   nil)]
    (set ?group group)
    (autocmd! event {: group : pattern : callback})))

{: watch-to-update!}
