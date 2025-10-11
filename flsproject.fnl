{:lua-version "lua5.1"
 :extra-globals "describe* it* describe it setup teardown before_each after_each"
 :libraries {:nvim true}
 ;; NOTE: fennel-ls does not resolve keys handled via metatable.
 :lints {:unknown-module-field false}
 :macro-path "fnl/?.fnl;fnl/?/init.fnl;?.fnl;?/init.fnl"
 :fennel-path "fnl/?.fnl;fnl/?/init.fnl;?.fnl;?/init.fnl"}
