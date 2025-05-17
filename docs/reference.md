# Reference

<!--toc:start-->

- [Reference](#reference)
  - [Options in `.nvim-thyme.fnl`](#options-in-nvim-thymefnl)
    - [compiler-options](#compiler-options)
    - [macro-path](#macro-path)
    - [max-rollbacks](#max-rollbacks)
  - [Functions](#functions)
    - [`thyme.loader`](#thymeloader)
    - [`thyme.setup` or `thyme:setup`](#thymesetup-or-thymesetup)
    - [Functions at `thyme.fennel`](#functions-at-thymefennel)
    - [Functions `pcall`-able](#functions-pcall-able)
      - [`thyme.call.cache.clear`](#thymecallcacheclear)
      - [`thyme.call.cache.open`](#thymecallcacheopen)
    - [Keymaps](#keymaps)
  - [Commands](#commands)
    - [Fennel Wrapper Commands](#fennel-wrapper-commands)
      - [`:Fnl {fnl-expr}`](#fnl-fnl-expr)
      - [`:FnlBuf [bufname]`](#fnlbuf-bufname)
      - [`:FnlFile [file]`](#fnlfile-file)
      - [`:FnlCompileString {fnl-expr}`](#fnlcompilestring-fnl-expr)
      - [`:FnlCompileBuf [bufname]`](#fnlcompilebuf-bufname)
      - [`:FnlCompileFile [file]`](#fnlcompilefile-file)
    - [Fennel Misc. Commands](#fennel-misc-commands)
      - [`:FnlAlternate`](#fnlalternate)
    - [Thyme General Commands](#thyme-general-commands)
      - [`:ThymeUninstall`](#thymeuninstall)
    - [Thyme Config Commands](#thyme-config-commands)
      - [`:ThymeConfigOpen`](#thymeconfigopen)
    - [Thyme Cache Commands](#thyme-cache-commands)
      - [`:ThymeCacheClear`](#thymecacheclear)
      - [`:ThymeCacheOpen`](#thymecacheopen)
    - [Thyme Rollback Commands](#thyme-rollback-commands)
      - [`:ThymeRollbackSwitch {target}`](#thymerollbackswitch-target)
      - [`:ThymeRollbackMount {target}`](#thymerollbackmount-target)
      - [`:ThymeRollbackUnmount {target}`](#thymerollbackunmount-target)
      - [`:ThymeRollbackUnmountAll`](#thymerollbackunmountall)

<!--toc:end-->

<!-- panvimdoc-ignore-start -->

## Options in `.nvim-thyme.fnl`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
options ~                                                     *thyme-options*
.nvim-thyme.fnl ~                                           *.nvim-thyme.fnl*
-->

The configurations for [nvim-thyme][] should be managed in `.nvim-thyme.fnl`
at the path `vim.fn.stdpath('config')` returns.

When `.nvim-thyme.fnl` is missing at the directory on nvim startup,
[nvim-thyme][] will ask you to generate it with recommended settings:
See the file [.nvim-thyme.fnl.example][].

### compiler-options

(default: `{}`)

The options to be passed to `fennel` functions which takes an `options` table
argument: `allowedGlobals`, `correlate`, `useMetadata`, and so on.

See the official Fennel API documentation: <https://fennel-lang.org/api>

### macro-path

(default: `"./fnl/?.fnlm;./fnl/?/init.fnlm;./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"`)

The path patterns for `fennel.macro-path` to find Fennel macro module path.

Relative path markers (`./`) are internally copied and replaced with each
directory path on `&runtimepath`.
(Feel free to skip over it, but the replacements are optimized, filtered by
the directories suffixed by `?` in this option, e.g, with the default option
value, `./` prefixes will be only replaced with the paths that contains `fnl`
directory on `&runtimepath`.)

Note: Unlike the `macro-path` option, `nvim-thyme` does _**not** provide any
option to modify `fennel.path`._ For general Fennel modules, `nvim-thyme` is
only designed to search through the path:
`./fnl/?.fnl;./fnl/?/init.fnl` where each `.` prefix represents the result
path of `(vim.fn.stdpath :config)`.

### max-rollbacks

(default: `5`)

Keep the number of backups for rollback at most. Set `0` to disable it.

Note: Unlike the rollback system for compile error, [nvim-thyme][] does
_**not** provide any rollback system for nvim **runtime** error._
Such a feature should be realized independently of a runtime compiler plugin.

## Functions

### `thyme.loader`

The core function of [nvim-thyme][].
The loader is to be appended to [package.loaders] manually by user
before loading any Fennel modules.

```lua
-- Wrapping the `require` in `function-end` is important for lazy-load.
table.insert(package.loaders, function(...)
  return require("thyme").loader(...) -- Make sure to `return` the result!
end)
```

> [!IMPORTANT]
> Before loading any Fennel module,
> you also have to prepend `/a/path/to/thyme/compile`
> which contains a substring `"/thyme/compile"`
> in `&runtimepath`, for example,
> `vim.opt.rtp:prepend(vim.fn.stdpath('cache') .. '/thyme/compiled')`.

<!-- panvimdoc-ignore-start -->

### `thyme.setup` or `(thyme:setup)`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
thyme.setup                                                     *thyme.setup*
(thyme:setup)                                                 *(thyme:setup)*
-->

Define [commands](#commands) and [keymaps](#keymaps).

It also defines an autocmd group `ThymeWatch` to keep compiled lua files
up-to-date.

> [!IMPORTANT]
> No arguments are allowed by `thyme.setup`.\
> You should manage all the options in [.nvim-thyme.fnl][] instead.

For the Lua ideom `require("thyme").setup()` in Fennel,
the method call syntax `(thyme:setup)` is supported.
Therefore, the following weird syntax with `.` and additional parentheses

```fennel
((require :thyme) (. :setup))
;; or
((-> (require :thyme) (. :setup)))
```

can be replaced by the following syntax with `:`

```fennel
(-> (require :thyme) (: :setup))
```

This function is to be called
_after_ [VimEnter][] wrapped in [vim.schedule][],
or later.
For example,

```lua
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = vim.schedule_wrap(function()
    require("thyme").setup()
    require("others")
  end,
})
```

or if you carefully manage your config files
where some Fennel file are loaded in `vim.schedule` on `VimEnter` elsewhere,
put the following code in such a Fennel file:

```fennel
(-> (require :thyme)
    (: :setup))
```

### Functions at `thyme.fennel`

<!--
TODO: Describe every `thyme.fennel.<foobar>` functions?
-->

Provides a set of Fennel wrapper functions
corresponding to [Fennel Wrapper Commands][].

Unless otherwise noted,
the functions named with `_` are equivalent to those with `-`.

```vim
:= require("thyme").fennel
```

### Functions `pcall`-able

Some `thyme.call.<foo.bar.baz>`-modules are provided.

They are useful to call them
without worrying about [thyme]'s validity,
and about the interface dependencies
when you are considering another Fennel compiler system.

#### `thyme.call.cache.clear`

Equivalent to [:ThymeCacheClear][], but it should work without [thyme.setup].

This function is useful to be called
on [githooks](https://git-scm.com/docs/githooks)
without worrying about [thyme]'s validity,
and about the interface dependencies
when you were considering another Fennel compiler system.

For example, add the following lines in `.githooks/post-checkout`
with executable permission:

```sh
if type nvim >/dev/null; then
  nvim --headless -c "lua pcall(require, 'thyme.call.cache.clear')" +q
fi
```

#### `thyme.call.cache.open`

Equivalent to [:ThymeCacheOpen][], but it should work without [thyme.setup].

### Keymaps

<!-- panvimdoc-include-comment
<Plug>(thyme-operator-echo-eval)            *<Plug>(thyme-operator-echo-eval)*
<Plug>(thyme-operator-echo-eval-compiler)   *<Plug>(thyme-operator-echo-eval-compiler)*
<Plug>(thyme-operator-echo-macrodebug)      *<Plug>(thyme-operator-echo-macrodebug)*
<Plug>(thyme-operator-echo-compile-string)  *<Plug>(thyme-operator-echo-compile-string)*
<Plug>(thyme-operator-print-eval)           *<Plug>(thyme-operator-print-eval)*
<Plug>(thyme-operator-print-eval-compiler)  *<Plug>(thyme-operator-print-eval-compiler)*
<Plug>(thyme-operator-print-macrodebug)     *<Plug>(thyme-operator-print-macrodebug)*
<Plug>(thyme-operator-print-compile-string) *<Plug>(thyme-operator-print-compile-string)
-->

The keymaps are defined with [thyme.setup][].

The `echo` versions do not mess up cmdline-history as `:echo` does not.

- `<Plug>(thyme-operator-echo-eval)`
- `<Plug>(thyme-operator-echo-eval-compiler)`
- `<Plug>(thyme-operator-echo-macrodebug)`
- `<Plug>(thyme-operator-echo-compile-string)`

The `print` versions leave its results in cmdline-history as `vim.print` does.

- `<Plug>(thyme-operator-print-eval)`
- `<Plug>(thyme-operator-print-eval-compiler)`
- `<Plug>(thyme-operator-print-macrodebug)`
- `<Plug>(thyme-operator-print-compile-string)`

## Commands

The commands are defined by [thyme.setup][].

### Fennel Wrapper Commands

<!-- panvimdoc-ignore-start -->

#### `:Fnl {fnl-expr}`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:Fnl ~                                                           *thyme-:Fnl*
-->

Display the result of applying [fennel.eval][] to `{fnl-expr}`,
but respects your [&runtimepath][].

<!-- panvimdoc-ignore-start -->

#### `:FnlBuf [bufname]`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlBuf ~                                                     *thyme-:FnlBuf*
-->

Display the result of applying [fennel.dofile][] but to `[bufname]`,
but respects your [&runtimepath][].

If no `[bufname]` is given, it evaluates the current buffer.

<!-- panvimdoc-ignore-start -->

<!-- panvimdoc-ignore-start -->

#### `:FnlFile [file]`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlFile ~                                                   *thyme-:FnlFile*
-->

Display the result of applying [fennel.dofile][] to `[file]`,
but respects your [&runtimepath][].

If no `[file]` is given, it evaluates the current file.

#### `:FnlCompileString {fnl-expr}`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlCompileString ~                                 *thyme-:FnlCompileString*
-->

Almost equivalent to [:Fnl][];
however, it does not evaluate the {fnl-expr},
but only returns the compiled lua results.

<!-- panvimdoc-ignore-start -->

#### `:FnlCompileBuf [bufname]`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlCompileBuf ~                                       *thyme-:FnlCompileBuf*
-->

Almost equivalent to [:FnlBuf][];
however, it does not evaluate the [bufname] (or current buffer),
but only returns the compiled lua results.

<!-- panvimdoc-ignore-start -->

#### `:FnlCompileFile [file]`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlCompileFile ~                                     *thyme-:FnlCompileFile*
-->

Almost equivalent to [:FnlBuf][];
however, it does not evaluate the [file] (or current file),
but only returns the compiled lua results.

<!-- panvimdoc-ignore-start -->
<!--
TODO: Add the spec tests first.

#### `:FnlCompileFile[!] [src-file] [dest-file]`

With `!`, it will write the compiled lua results to `[dest-file]`.
-->

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlCompileFile ~                                     *thyme-:FnlCompileFile*
-->

### Fennel Misc. Commands

<!-- panvimdoc-ignore-start -->

#### `:FnlAlternate`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlAlternate ~                                         *thyme-:FnlAlternate*
-->

Try to open the alternate file of current buffer:

- For a Fennel file, find the corresponding Lua file.
- For a Lua file, find the corresponding Fennel file.

This command will search in the following order:

1. The thyme's Lua caches
2. The directory of the target file
3. The corresponding `/fnl/` or `/lua/` directory

### Thyme General Commands

#### `:ThymeUninstall`

Remove all the cache, data, state, and log files,
which are implicitly managed by [nvim-thyme][].

This command is so safe
as it does **not** affect your [.nvim-thyme.fnl][]
and any of your configuration files.

When you have some issues with [nvim-thyme][],
try [:ThymeCacheClear][] first instead.
When the command does not resolve your issue,
then try this command [:ThymeUninstall][].

### Thyme Config Commands

#### `:ThymeConfigOpen`

Open your [.nvim-thyme.fnl][] file.

### Thyme Cache Commands

#### `:ThymeCacheClear`

Clear all the Lua caches managed by [nvim-thyme][].

If you failed to define the command [:ThymeCacheClear][] for some reasons,
please execute [:lua require('thyme.call.cache.clear')](#thymecallcacheclear)
manually in Command line instead.

See also [:ThymeUninstall][].

#### `:ThymeCacheOpen`

Open the root directory of the Lua caches managed by [nvim-thyme][].

### Thyme Rollback Commands

#### `:ThymeRollbackSwitch {target}`

Prompt to switch to the active backup of the `{target}`.

Any compile errors of the `{target}` of Fennel module will be rolled back to the active backup.
This switch also affects the mounted backup of `{target}`.

#### `:ThymeRollbackMount {target}`

Mount the active backup of the `{target}`.

Neovim will load the mounted backups instead of your modules with the same name.
You should run [:ThymeRollbackUnmount][] or [:ThymeRollbackUnmountAll][]
to restore the mount state.

#### `:ThymeRollbackUnmount {target}`

Unmount the mounted backups for the `{target}`.

#### `:ThymeRollbackUnmountAll`

Unmount the mounted backups.

[.nvim-thyme.fnl.example]: ../.nvim-thyme.fnl.example
[package.loaders]: https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
[VimEnter]: https://neovim.io/doc/user/autocmd.html#VimEnter
[vim.schedule]: https://neovim.io/doc/user/lua.html#vim.schedule()
[nvim-thyme]: https://github.com/aileot/nvim-thyme
[thyme]: https://github.com/aileot/nvim-thyme
[nvim-laurel]: https://github.com/aileot/nvim-laurel
[.nvim-thyme.fnl]: #options-for-nvim-thymefnl
[thyme.setup]: #thymesetup-or-thymesetup
[&runtimepath]: https://vim-jp.org/vimdoc-ja/options.html#'runtimepath'
[fennel.eval]: https://fennel-lang.org/api#evaluate-a-string-of-fennel
[fennel.dofile]: https://fennel-lang.org/api#evaluate-a-file-of-fennel
[Fennel Wrapper Commands]: #fennel-wrapper-commands
[:Fnl]: #fnlfnl-expr
[:FnlBuf]: #fnlbuf-bufname
[:ThymeUninstall]: #thymeuninstall
[:ThymeCacheOpen]: #thymecacheopen
[:ThymeCacheClear]: #thymecacheclear
[:ThymeRollbackUnmount]: #thymerollbackunmount-target
[:ThymeRollbackUnmountAll]: #thymerollbackunmountall
