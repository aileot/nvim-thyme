;; extends

;; NOTE: The injections are supposed to be used on the extui feature.
;; NOTE: ftplugin/vim/injections.lua can replace this injection queries, but it
;; affects startuptime while treesitter highlighting is applied asynchronously.

;; TODO: Add predicate to disable injections?
;; TODO: Replace this queries/ with query.fnl to make the injections optional?

(user_command
  (command_name) @_excmd
  . (arguments) @injection.content
  (#any-of? @_excmd
    "Fnl"
    "FnlCompile")
  (#set! injection.language "fennel")
  (#set! injection.include-children))

;; For dropin feature.
((ERROR) @injection.content
  (#lua-match? @injection.content "^:?%s*[%[%({]")
  (#set! injection.language "fennel")
  (#set! injection.include-children))
