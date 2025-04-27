(local {: do-nothing} (require :thyme.utils.general))

(fn reload-module! [module-name ?opts]
  "Drop `module-name` from either `package.loaded` or `fennel.macro-loaded`.
@param module-name string
@param ?opts.notifier false|function
@param ?opts.live-reload boolean|table"
  ;; NOTE: If they are nil, `require` will search the module file again.
  ;; NOTE: There is an issue that module local state variable will be
  ;; reset.
  ;; NOTE: reloading modules only matters on &rtp.
  (let [fennel (require :fennel)
        opts (or ?opts {:notifier {} :live-reload false})
        notify! (or opts.notifier.reload do-nothing)
        live-reload? (and opts.live-reload
                          (or (= true opts.live-reload)
                              (not= false opts.live-reload.enabled)))]
    (case (. package.loaded module-name)
      mod
      (do
        (tset package.loaded module-name nil)
        ;; Testing module if safe to update.
        ;; NOTE: `require` updates package.loaded[module-name] if nil.
        (case (xpcall #(require module-name) fennel.traceback)
          (true _) (if live-reload?
                       (notify! (.. module-name
                                    " has been reloaded on package.loaded"))
                       (tset package.loaded module-name mod))
          (false msg) (do
                        ;; Restore the saved module loader.
                        (tset package.loaded module-name mod)
                        (error msg))))
      ;; NOTE: fennel.macro-loaded is only used by import-macros,
      ;; require-macros, and `require` within the default compiler scope.
      ;; Ref: src/fennel/specials.fnl @1108
      ;; NOTE: macro-loaded would only be loaded in a nvim session where
      ;; compile is required.
      nil
      (case (. fennel.macro-loaded module-name)
        mod (let [{: search-fnl-macro-on-rtp} (require :thyme.searcher.macro)]
              (tset fennel.macro-loaded module-name nil)
              ;; Testing module if safe to update.
              ;; NOTE: `require` is unsuitable here because it does not run in
              ;; compiler sandbox.
              (case (xpcall #(search-fnl-macro-on-rtp module-name)
                            fennel.traceback)
                (true loader) (if live-reload?
                                  (do
                                    (tset fennel.macro-loaded module-name
                                          (loader module-name))
                                    (notify! (.. module-name
                                                 " has been reloaded on fennel.macro-loaded")))
                                  (tset fennel.macro-loaded module-name mod))
                (false msg) (do
                              ;; Restore the saved module loader.
                              (tset fennel.macro-loaded module-name mod)
                              (error msg))))))))

{: reload-module!}
