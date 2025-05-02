(local {: debug? : config-filename : config-path} (require :thyme.const))
(local {: file-readable? : assert-is-fnl-file : read-file : write-fnl-file!}
       (require :thyme.utils.fs))

;; NOTE: Please keep this security check simple.
(local nvim-appname vim.env.NVIM_APPNAME)
(local secure-nvim-env? (or (= nil nvim-appname) (= "" nvim-appname)))

(local default-opts ;
       {:max-rollbacks 10
        ;; TODO: Inplement :preproc and set the default value to `#$`.
        :preproc nil
        :compiler-options {}
        :fnl-dir "fnl"
        ;; Set to fennel.macro-path for macro modules.
        :macro-path (-> ["./fnl/?.fnlm"
                         "./fnl/?/init.fnlm"
                         "./fnl/?.fnl"
                         "./fnl/?/init-macros.fnl"
                         "./fnl/?/init.fnl"]
                        (table.concat ";"))})

(local cache {})

(set cache.main-config
     (setmetatable {}
       {:__index (fn [self k]
                   (if (= k "?error-msg")
                       ;; As a placeholder.
                       nil
                       (case (rawget default-opts k)
                         val (do
                               (rawset self k val)
                               val)
                         _ (error (.. "unexpected option detected: "
                                      (vim.inspect k))))))
        :__newindex (if debug?
                        (fn [self k v]
                          (rawset self k v))
                        #(error "no option can be overridden by this table"))}))

(when (not (file-readable? config-path))
  ;; Generate main-config-file if missing.
  (case (vim.fn.confirm (: "Missing \"%s\" at %s. Generate and open it?"
                           :format config-filename (vim.fn.stdpath :config))
                        "&No\n&yes" 1 :Warning)
    2 (let [this-dir (-> (debug.getinfo 1 "S")
                         (. :source)
                         (: :sub 2)
                         (vim.fs.dirname))
            example-config-filename (.. config-filename ".example")
            [example-config-path] (vim.fs.find example-config-filename
                                               {:upward true
                                                :type "file"
                                                :path this-dir})
            recommended-config (read-file example-config-path)]
        (write-fnl-file! config-path recommended-config)
        (vim.cmd.tabedit config-path)
        (-> #(when (= config-path (vim.api.nvim_buf_get_name 0))
               (case (vim.fn.confirm "Trust this file? Otherwise, it will ask your trust again on nvim restart"
                                     "&Yes\n&no" 1 :Question)
                 2 (error (.. "abort trusting " config-path))
                 _ (vim.cmd.trust)))
            (vim.defer_fn 800)))
    _ (error "abort proceeding with nvim-thyme")))

(fn read-config [config-file-path]
  "Return config table of `config-file-path`.
@param config-file string a directory path.
@return table"
  (assert-is-fnl-file config-file-path)
  ;; NOTE: fennel is likely to get into loop or previous error.
  (let [fennel (require :fennel)
        config-code (if secure-nvim-env?
                        (read-file config-file-path)
                        (vim.secure.read config-file-path))
        compiler-options {:error-pinpoint ["|>>" "<<|"]
                          :filename config-file-path}
        _ (set cache.evaluating? true)
        ?config (fennel.eval config-code compiler-options)
        _ (set cache.evaluating? false)]
    (or ?config {})))

(fn get-config []
  "Return the config found at stdpath('config') on the first load.
@return table Thyme config"
  (if cache.evaluating?
      ;; NOTE: This expects `(pcall require missing-mdodule)` in .nvim-thyme.fnl.
      {:?error-msg (.. "recursion detected in evaluating " config-filename)}
      (next cache.main-config)
      cache.main-config
      (let [user-config (read-config config-path)]
        (each [k v (pairs user-config)]
          ;; NOTE: By-pass metatable __newindex tweaks, which are only intended
          ;; to users. Unless $THYME_DEBUG is set, The config table must NOT be
          ;; overridden by the other locations than here.
          (rawset cache.main-config k v))
        cache.main-config)))

(fn config-file? [path]
  "Tell if `path` is a thyme's config file.
@param path string
@return boolean"
  ;; NOTE: Just in case, do not compare in full path.
  (= config-filename (vim.fs.basename path)))

{: get-config : config-file?}
