(import-macros {: when-not : nvim-get-option} :thyme.macros)

(local Path (require :thyme.utils.path))

(local config-filename :.nvim-thyme.fnl)

(local stdpath-config (vim.fn.stdpath :config))

(local rtp (nvim-get-option :rtp))

;; Note: In case config is managed over symbolic link or something else,
;; compare it with a each project config later.
(local config-path (Path.join stdpath-config config-filename))

(local cache-prefix
       (assert (or (rtp:match "([^,]+/thyme/compile[^,]-),")
                   (rtp:match "([^,]+/thyme/compile[^,]-)$"))
               "&runtimepath must contains a unique path which literally includes `/thyme/compile`."))

;; Note: No need to set `/compiled/*` because Lua `require` only search
;; for a file per module name unlike `:runtime!` in Vim script.
;; PERF: All the double-underscored options must be set here and treated
(local lua-cache-prefix (-> (Path.join cache-prefix :lua)
                            (vim.fn.expand)))

(local fnl-src-prefix (Path.join stdpath-config :fnl))
(local resolved-src-prefix (vim.fn.resolve fnl-src-prefix))
(local fnl-src-prefixes
       (if (= fnl-src-prefix resolved-src-prefix)
           [fnl-src-prefix]
           [fnl-src-prefix resolved-src-prefix]))

{: stdpath-config
 : lua-cache-prefix
 : config-filename
 : config-path
 :state-prefix (Path.join (vim.fn.stdpath :state) :thyme)
 ;; TODO: Consider symbolic links.
 :fnl-src-prefix (Path.join stdpath-config :fnl)}
