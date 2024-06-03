(import-macros {: when-not : nvim-get-option} :thyme.macros)

(local {: config-filename : config-path} (require :thyme.const))
(local {: file-readable?
        : assert-is-fnl-file
        : read-file
        : write-fnl-file!
        : uv} (require :thyme.utils.fs))

(local cache {:main-config nil :config-list {}})

;; Note: Please keep this security check simple.
(local nvim-appname vim.env.NVIM_APPNAME)
(local secure-nvim-env? (or (= nil nvim-appname) (= "" nvim-appname)))

;; fnlfmt: skip
(local default-opts ;
       {:rollback true
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
                        "&Yes\n&no" 1 :Warning)
    2 (error "abort proceeding with nvim-thyme")
    _
    (let [recommended-config ";; Generated with recommended options by nvim-thyme.
{:rollback true
 :compiler-options {:correlate true
                    ;; :compilerEnv _G
                    :error-pinpoint [\"|>>\" \"<<|\"]}
 ;; The path patterns for fennel.macro-path to find Fennel macro module path.
 ;; Relative path markers (`.`) are internally replaced with the paths on
 ;; &runtimepath filtered by the directories suffixed by `?`, e.g., `fnl/` in
 ;; `./fnl/?.fnl`.
 :macro-path \"./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl\"}"]
      ;; TODO: It's desirable to write file later with fennel.view.
      (write-fnl-file! config-path recommended-config)
      (vim.cmd.tabedit config-path)
      (-> #(when (= config-path (vim.api.nvim_buf_get_name 0))
             (case (vim.fn.confirm "Trust this file? Otherwise, it will ask your trust again on nvim restart"
                                   "&Yes\n&no" 1 :Question)
               2 (error (.. "abort trusting " config-path))
               _ (vim.cmd.trust)))
          (vim.defer_fn 800)))))

;; (fn find-config-file [path]
;;   "Return the config path, or `nil` if not detected.
;; @param path
;; @return string?"
;;   (case (vim.fs.find config-filename
;;                      {:upward true :type :file :stop (uv.os_homedir) : path})
;;     [project-config-path] project-config-path))

(var get-main-config nil)

(fn read-config [config-file-path]
  "Return config table of `config-file-path`.
@param config-file string a directory path.
@return table"
  (assert-is-fnl-file config-file-path)
  (let [fs-stat (uv.fs_stat config-file-path)
        ;; Note: fennel is likely to get into loop or previous error.
        fennel (require :fennel)
        config-table (case (. cache.config-list config-file-path)
                       (where ?cache
                              (or (= nil ?cache) ;
                                  (< ?cache.mtime.sec fs-stat.mtime.sec)))
                       (let [config-lines (if secure-nvim-env?
                                              (read-file config-file-path)
                                              (vim.secure.read config-file-path))
                             compiler-options {:error-pinpoint false}
                             ?config (fennel.eval config-lines compiler-options)
                             config (or ?config {})
                             ;; Note: It would be so nervous to watch nsec, too.
                             mtime fs-stat.mtime]
                         (tset cache.config-list config-file-path
                               {: config : mtime})
                         config)
                       {: config} config)
        config (vim.tbl_deep_extend :keep config-table default-opts)]
    config))

(set get-main-config ;
     (fn []
       "Return the config found at stdpath('config').
        @return table Thyme config"
       (or cache.main-config ;
           (let [main-config (read-config config-path)]
             (set cache.main-config main-config)
             main-config))))

(fn config-file? [path]
  "Tell if `path` is a thyme's config file.
@param path string
@return boolean"
  (= config-filename (vim.fs.basename path)))

(lambda get-option-value [config key]
  "Return the option value for `config`.
@return any config value"
  (or (rawget config key) ;
      (rawget default-opts key)))

{: get-main-config : read-config : get-option-value : config-file?}
