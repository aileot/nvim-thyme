(fn inject-vim-cmd-arg-query! [cmd-name injection-language]
  "Inject treesitter queries for `cmd-name-pattern` to inject
`injection-language` for the arguments of the matched Vim user commands.
@param cmd-name-pattern string
@param injection-language string"
  (let [base-filetype "vim"
        cmd-query (-> ";; extends
(user_command
  (command_name) @_cmd
  . (arguments) @injection.content
  (#eq? @_cmd %q)
  (#set! injection.language %q)
  (#set! injection.include-children))"
                      (: :format cmd-name injection-language))]
    (vim.treesitter.query.set base-filetype :injections cmd-query)))

(fn inject-dropin-query! [injection-language]
  "Inject treesitter queries for `cmd-name-pattern` to inject
`injection-language` for the arguments of the matched Vim user commands.
@param cmd-name-pattern string
@param injection-language string"
  (let [base-filetype "vim"
        dropin-query (-> ";; extends
((ERROR) @injection.content
  (#set! injection.language %q)
  (#set! injection.include-children))"
                         (: :format injection-language))]
    (vim.treesitter.query.set base-filetype :injections dropin-query)))

{: inject-vim-cmd-arg-query! : inject-dropin-query!}
