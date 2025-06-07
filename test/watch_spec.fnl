(import-macros {: describe* : it*} :test.helper.busted-macros)

(local {: prepare-config-fnl-file! : remove-context-files!}
       (include :test.helper.util))

(local thyme (require :thyme))
(local Config (require :thyme.config))

(describe* "ThymeWatch"
  (setup (fn []
           (thyme:setup)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "can detect changes on a Fennel file on FileChangedShellPost"
    (let [default-strategy Config.watch.strategy]
      (before_each (fn []
                     (set Config.watch.strategy "always-clear-all")))
      (after_each (fn []
                    (set Config.watch.strategy default-strategy)))
      (it* "should not throw error when editing a buffer but externally removed later"
        (let [mod "foo"
              filename (.. mod ".fnl")
              fnl-path (prepare-config-fnl-file! filename "1")]
          (vim.cmd.edit fnl-path)
          (assert.equals 1 (require mod))
          (tset package.loaded mod nil)
          (-> ["rm" fnl-path]
              (vim.system)
              (: :wait))
          (assert.has_no_error #(vim.cmd :checktime))
          (tset package.loaded mod nil)
          (vim.cmd.bdelete fnl-path)))
      (describe* "should clear the cache for modified Fennel file;"
        (let [mod "foo"
              filename (.. mod ".fnl")]
          (it* "thus, each `require` should return different results on FileChangedShellPost event twice."
            (let [fnl-path (prepare-config-fnl-file! filename "1")]
              (vim.cmd.edit fnl-path)
              (assert.equals 1 (require mod))
              (tset package.loaded mod nil)
              (-> ["sed" "-i" "s/[0-9]/2/g" fnl-path]
                  (vim.system)
                  (: :wait))
              (vim.cmd :checktime)
              (assert.equals 2 (require mod))
              (tset package.loaded mod nil)
              (-> ["sed" "-i" "s/[0-9]/3/g" fnl-path]
                  (vim.system)
                  (: :wait))
              (vim.cmd :checktime)
              (assert.equals 3 (require mod))
              (tset package.loaded mod nil)
              (vim.cmd.bdelete fnl-path)
              (vim.fn.delete fnl-path))))))))

(describe* "ThymeWatch"
  (setup (fn []
           (thyme:setup)))
  (after_each (fn []
                (remove-context-files!)))
  (describe* "with strategy=always-clear-all"
    (let [default-strategy Config.watch.strategy]
      (before_each (fn []
                     (set Config.watch.strategy "always-clear-all")))
      (after_each (fn []
                    (set Config.watch.strategy default-strategy)))
      (describe* "should clear the cache for modified Fennel file;"
        (let [mod "foo"
              filename (.. mod ".fnl")]
          (it* "thus, each `require` should return different results on BufWritePost event twice."
            ;; NOTE: `prepare-config-fnl-file!` creates a new file per call; thus,
            ;; it should be called in each `it` block.
            (let [path (prepare-config-fnl-file! filename "1")]
              (assert.equals 1 (require mod))
              (tset package.loaded mod nil)
              (vim.cmd.edit path)
              (vim.api.nvim_buf_set_lines 0 0 -1 true ["2"])
              (vim.cmd.write path)
              (assert.equals 2 (require mod))
              (tset package.loaded mod nil)
              (vim.api.nvim_buf_set_lines 0 0 -1 true ["3"])
              (vim.cmd.write path)
              (assert.equals 3 (require mod))
              (tset package.loaded mod nil)
              (vim.cmd.bdelete path)
              (vim.fn.delete path))))))))

;; NOTE: It affect other tests even in `pending`.
;; (pending (it* "however, nvim cannot detect changes by `file:write`."
;;            (let [path (prepare-config-fnl-file! filename "1")]
;;              (assert.equals 1 (require mod))
;;              (tset package.loaded mod nil)
;;              (vim.cmd.edit path)
;;              (with-open [f (assert (io.open path "w"))]
;;                (f:write "2"))
;;              (vim.cmd :checktime)
;;              (assert.equals 1 (require mod))
;;              (tset package.loaded mod nil)
;;              (with-open [f (assert (io.open path "w"))]
;;                (f:write "3"))
;;              (vim.cmd :checktime)
;;              (assert.equals 1 (require mod))
;;              (tset package.loaded mod nil)
;;              (vim.cmd.bdelete path)
;;              (vim.fn.delete path)))))))))

;; (describe* "ThymeWatch on macro file"
;;   (let [default-watch-strategy Config.watch.strategy]
;;     (setup (fn []
;;              (thyme:setup)))
;;     (after_each (fn []
;;                   (vim.cmd "% bdelete")
;;                   (set Config.watch.strategy default-watch-strategy)
;;                   (remove-context-files!)))
;;     (describe* "with config.watch.macro-strategy=recompile"
;;       (before_each (fn []
;;                      (set Config.watch.strategy "recompile")))
;;       (describe* "detecting changes on a macro file on BufWritePost"
;;         (let [macro-mod "macro-mod"
;;               macro-filename (.. macro-mod ".fnl")
;;               dependent-mod "dependent-mod"
;;               dependent-filename (.. dependent-mod ".fnl")]
;;           (it* "should recompile its dependent Fennel files change on BufWritePost once."
;;             (let [macro-path (prepare-config-fnl-file! macro-filename
;;                                                        "{:test (fn [] 1)}")
;;                   dependent-path (prepare-config-fnl-file! dependent-filename
;;                                                            (-> "(import-macros {: test} :%s) (test)"
;;                                                                (: :format
;;                                                                   macro-mod)))]
;;               (vim.cmd.edit macro-path)
;;               (assert.equals 1 (require dependent-mod))
;;               (tset package.loaded dependent-mod nil)
;;               (vim.api.nvim_buf_set_lines 0 0 -1 true ["{:test (fn [] 2)}"])
;;               (vim.cmd.write macro-path)
;;               (assert.equals 2 (require dependent-mod))
;;               (tset package.loaded dependent-mod nil)
;;               (vim.fn.delete macro-path)
;;               (vim.fn.delete dependent-path)
;;               (vim.cmd.bdelete macro-path))))))))
