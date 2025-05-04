;;; This is just a autocmd wrapper of thyme.user.check.
;;; It only helps users write shorter than with vim.api.nvim_create_augroup
;;; and vim.api.nvim_create_autocmd.

(local {: config-path : lua-cache-prefix} (require :thyme.const))
(local {: clear-cache!} (require :thyme.compiler.cache))
(local {: check-to-update!} (require :thyme.user.check))

(local {: get-config} (require :thyme.config))

(var ?group nil)

(macro augroup! [...]
  `(vim.api.nvim_create_augroup ,...))

(macro autocmd! [...]
  `(vim.api.nvim_create_autocmd ,...))

(fn watch-files! [?opts]
  "Add an autocmd in augroup named `ThymeWatch` to watch fennel files.
It overrides the previously defined `autocmd`s if both event and pattern are
the same.
@param ?opts.verbose boolean (default: false) notify if successfully compiled file.
@param ?opts.dependent-files 'delete'|'ignore' (default: 'delete')
@param ?opts.live-reload boolean WIP (default: false)
@param ?opts.event string|string[] autocmd-event
@param ?opts.pattern string|string[] autocmd-pattern
@return number autocmd-id"
  (let [group (or ?group (augroup! :ThymeWatch {}))
        config (get-config)
        opts (if ?opts
                 (vim.tbl_deep_extend :force config.watch ?opts)
                 config.watch)
        event opts.event
        pattern opts.pattern
        callback (fn [{:match fnl-path}]
                   (let [resolved-path (vim.fn.resolve fnl-path)]
                     (if (= config-path resolved-path)
                         (when (clear-cache!)
                           (vim.notify (.. "Cleared cache: " lua-cache-prefix)))
                         (case (pcall check-to-update! resolved-path opts)
                           (false msg) (vim.notify_once msg
                                                        vim.log.levels.ERROR)))
                     ;; Prevent not to destroy the autocmd.
                     nil))]
    (set ?group group)
    (autocmd! event {: group : pattern : callback})))

{: watch-files!}
