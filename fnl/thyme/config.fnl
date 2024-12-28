(import-macros {: when-not : nvim-get-option} :thyme.macros)

(local {: config-filename : config-path} (require :thyme.const))
(local {: file-readable? : assert-is-fnl-file : read-file : write-fnl-file!}
       (require :thyme.utils.fs))

(local cache {:main-config nil})
(set cache.mt-config
     (setmetatable {}
       {:__index (fn [_ k]
                   (case (. cache.main-config k)
                     val val
                     _ (error (.. "unexpected option detected: "
                                  (vim.inspect k)))))
        :__newindex (if (= :1 vim.env.THYME_DEBUG)
                        (fn [_ k v]
                          (tset cache.main-config k v))
                        #(error "no option can be overridden by this table"))}))

;; Note: Please keep this security check simple.
(local nvim-appname vim.env.NVIM_APPNAME)
(local secure-nvim-env? (or (= nil nvim-appname) (= "" nvim-appname)))

(local default-opts ;
       {:rollback true
        ;; TODO: Inplement :preproc and set the default value to `#$`.
        :preproc nil
        :compiler-options {}
        ;; Set to fennel.macro-path for macro modules.
        :macro-path (-> ["./fnl/?.fnl"
                         "./fnl/?/init-macros.fnl"
                         "./fnl/?/init.fnl"]
                        (table.concat ";"))})

(when-not (file-readable? config-path)
  ;; Generate main-config-file if missing.
  (case (vim.fn.confirm (: "Missing \"%s\" at %s... Generate and open it?"
                           :format config-filename (vim.fn.stdpath :config))
                        "&No\n&yes" 1 :Warning)
    2 (let [recommended-config ";; recommended options of nvim-thyme
{:rollback true
 :compiler-options {:correlate true
                    ;; :compilerEnv _G
                    :error-pinpoint [\"|>>\" \"<<|\"]}
 ;; The path patterns for fennel.macro-path to find Fennel macro module path.
 ;; Relative path markers (`.`) are internally replaced with the paths on
 ;; &runtimepath filtered by the directories suffixed by `?`, e.g., `fnl/` in
 ;; `./fnl/?.fnl`.
 :macro-path \"./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl\"}"]
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
  ;; Note: fennel is likely to get into loop or previous error.
  (let [fennel (require :fennel)
        config-code (if secure-nvim-env?
                        (read-file config-file-path)
                        (vim.secure.read config-file-path))
        compiler-options {:error-pinpoint ["|>>" "<<|"]
                          :filename config-file-path}
        ?config (fennel.eval config-code compiler-options)
        config-table (or ?config {})
        config (vim.tbl_deep_extend :keep config-table default-opts)]
    config))

(fn get-config []
  "Return the config found at stdpath('config') on the first load.
@return table Thyme config"
  (when (= nil cache.main-config)
    (let [main-config (read-config config-path)]
      (set cache.main-config main-config)))
  cache.mt-config)

(fn config-file? [path]
  "Tell if `path` is a thyme's config file.
@param path string
@return boolean"
  ;; Note: Just in case, do not compare in full path.
  (= config-filename (vim.fs.basename path)))

{: get-config : config-file?}
