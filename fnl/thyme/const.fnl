(import-macros {: when-not : nvim-get-option} :thyme.macros)

(local Path (require :thyme.util.path))

(local config-filename :.nvim-thyme.fnl)

(local stdpath-config (vim.fn.stdpath :config))

(local rtp (nvim-get-option :rtp))

;; NOTE: In case config is managed over symbolic link or something else,
;; compare it with a each project config later.
(local config-path (vim.fn.resolve (Path.join stdpath-config config-filename)))

(local cache-prefix
       (assert (or (rtp:match "([^,]+/thyme/compile[^,]-),")
                   (rtp:match "([^,]+/thyme/compile[^,]-)$"))
               (.. "&runtimepath must contains a unique path which literally includes `/thyme/compile`; got "
                   (vim.inspect (vim.opt.rtp:get)))))

;; NOTE: No need to set `/compiled/*` because Lua `require` only search
;; for a file per module name unlike `:runtime!` in Vim script.
;; PERF: All the double-underscored options must be set here and treated
(local lua-cache-prefix (-> (Path.join cache-prefix :lua)
                            (vim.fn.expand)))

{:debug? (= :1 vim.env.THYME_DEBUG)
 : stdpath-config
 : lua-cache-prefix
 : config-filename
 : config-path
 :state-prefix (Path.join (vim.fn.stdpath :state) :thyme)}
