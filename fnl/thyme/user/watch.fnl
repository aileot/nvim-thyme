;;; This is just a autocmd wrapper of thyme.user.check.
;;; It only helps users write shorter than with vim.api.nvim_create_augroup
;;; and vim.api.nvim_create_autocmd.

(local fennel (require :fennel))

(local {: config-path : lua-cache-prefix} (require :thyme.const))
(local {: allowed?} (require :thyme.utils.trust))
(local Messenger (require :thyme.utils.messenger))
(local WatchMessenger (Messenger.new "watch"))
(local {: clear-cache!} (require :thyme.compiler.cache))
(local {: check-to-update!} (require :thyme.user.check))

(local Config (require :thyme.config))

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
        opts (if ?opts
                 (vim.tbl_deep_extend :force Config.watch ?opts)
                 Config.watch)
        callback (fn [{:match fnl-path}]
                   (let [resolved-path (vim.fn.resolve fnl-path)]
                     (if (= config-path resolved-path)
                         (do
                           (when (allowed? config-path)
                             ;; Automatically re-trust the user config file
                             ;; regardless of the recorded hash; otherwise, the
                             ;; user will be annoyed being asked to trust
                             ;; his/her config file on every change.
                             (vim.cmd :trust))
                           (when (clear-cache!)
                             (let [msg (.. "clear all the cache under "
                                           lua-cache-prefix)]
                               (WatchMessenger:notify! msg))))
                         (case (xpcall #(check-to-update! resolved-path opts)
                                       fennel.traceback)
                           (false msg) (WatchMessenger:notify-once! msg
                                                                    vim.log.levels.ERROR)))
                     ;; Prevent not to destroy the autocmd.
                     nil))]
    (set ?group group)
    (autocmd! opts.event {: group :pattern opts.pattern : callback})))

{: watch-files!}
