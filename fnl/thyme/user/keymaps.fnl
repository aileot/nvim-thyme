(import-macros {: str? : inc : first} :thyme.macros)

(local fennel (require :fennel))

(local tts (require :thyme.wrapper.treesitter))

(local fennel-wrapper (require :thyme.wrapper.fennel))

(local {: buf-marks->text} (require :thyme.utils.buf))

(local M {})

(fn M.define-keymaps! [?opts]
  ;; Note: &operatorfunc does not work on v:lua.require('foo')['bar'] format
  ;; instead of v:lua.require'foo'.bar: both `()` and `[]` do matter, avoid
  ;; "-" in names.
  (let [module-name :thyme.user.keymaps
        callback-prefix :new_operator_
        operator-callback-prefix :operator_
        methods [:echo :print]
        backend->lang {:compile-string :lua
                       :eval :fennel
                       :eval-compiler :fennel
                       :macrodebug :fennel}
        opts (or ?opts {})
        ?compiler-options opts.compiler-options]
    (each [backend lang (pairs backend->lang)]
      (let [eval-fn (. fennel-wrapper backend)]
        (each [_ method (ipairs methods)]
          (let [print-fn (. tts method)
                keymap-suffix (.. method "-" backend)
                callback-suffix (keymap-suffix:gsub "%-" "_")
                callback-name (.. callback-prefix callback-suffix)
                callback-in-string (: "require'%s'.%s" ;
                                      :format module-name callback-name)
                operator-callback-name (.. operator-callback-prefix
                                           callback-suffix)
                operator-callback-in-string (: "require'%s'.%s" ;
                                               :format module-name
                                               operator-callback-name)
                lhs (: "<Plug>(thyme-operator-%s)" :format keymap-suffix)
                ;; TODO: What implementation is the best for linewise operator?
                ;; Note: In Vim script expression, avoid double quotes.
                rhs/n (: "<Cmd>set operatorfunc=v:lua.%s<CR>g@" ;
                         :format operator-callback-in-string)
                rhs/x (: ":lua %s('<','>')<CR>" ;
                         :format callback-in-string)
                marks->print (fn [mark1 mark2]
                               (let [val (-> (buf-marks->text 0 mark1 mark2)
                                             (eval-fn ?compiler-options))
                                     text (if (str? val)
                                              val
                                              (fennel.view))]
                                 (print-fn text {: lang})))
                operator-callback #(marks->print "[" "]")]
            (vim.api.nvim_set_keymap :n lhs rhs/n {:noremap true})
            (vim.api.nvim_set_keymap :x lhs rhs/x {:noremap true :silent true})
            (tset M callback-name marks->print)
            (tset M operator-callback-name operator-callback)))))))

M
