;; extends

;; NOTE: The injections are supposed to be used on the extui feature.
;; NOTE: ftplugin/vim/injections.lua can replace this injection queries, but it
;; affects startuptime while treesitter highlighting is applied asynchronously.

;; TODO: Add predicate to disable injections?
;; TODO: Replace this queries/ with query.fnl to make the injections optional?

(user_command
  (command_name) @_excmd
  . (arguments) @injection.content
  (#any-lua-match? @_excmd
    "^F[nN][lL]?$"
    "^FnlCompile$")
  (#set! injection.language "fennel")
  (#set! injection.include-children))

(unknown_builtin_statement
  (unknown_command_name) @_excmd
  . (arguments) @injection.content
  (#any-lua-match? @_excmd
    ;; TODO: Extend dropin pattern for case-insensitive `:FnlCompile` and
    ;; others?
    "^f[nN][lL]?$")
  (#set! injection.language "fennel")
  (#set! injection.include-children))

;; For dropin feature.
((ERROR) @injection.content
  ;; NOTE: The content could start with `:`, and now it also support range.
  (#lua-match? @injection.content "^.-[%[%(%{]")
  ;; TODO: Exclude vim-range pattern from lang=fennel
  ;; (#gsub! @injection.content "^.-([%[%(%{].*)" "%1")
  (#set! injection.language "fennel")
  (#set! injection.include-children))
