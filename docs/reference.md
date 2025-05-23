# Reference

<!--toc:start-->

- [Reference](#reference)
  - [Options in `.nvim-thyme.fnl`](#options-in-nvim-thymefnl)
    - [compiler-options](#compiler-options)
    - [fnl-dir](#fnl-dir)
    - [macro-path](#macro-path)
    - [max-rollbacks](#max-rollbacks)
    - [notifier](#notifier)
    - [command.compiler-options](#commandcompiler-options)
    - [command.cmd-history.method](#commandcmd-historymethod)
    - [command.cmd-history.trailing-parens](#commandcmd-historytrailing-parens)
    - [watch.event](#watchevent)
    - [watch.pattern](#watchpattern)
  - [Functions](#functions)
    - [`thyme.loader`](#thymeloader)
    - [`thyme.setup` or `(thyme:setup)`](#thymesetup-or-thymesetup)
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
      - [`:FnlCompile {fnl-expr}`](#fnlcompile-fnl-expr)
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

The configurations for [nvim-thyme][nvim-thyme] should be managed in
`.nvim-thyme.fnl` at the path `vim.fn.stdpath('config')` returns.

When `.nvim-thyme.fnl` is missing at the directory on nvim startup,
[nvim-thyme][nvim-thyme] will ask you to generate it with recommended settings:
See the file [.nvim-thyme.fnl.example][.nvim-thyme.fnl.example].

### compiler-options

(default: `{}`)

The options to be passed to `fennel` functions which takes an `options` table
argument: `allowedGlobals`, `correlate`, `useMetadata`, and so on.

See the official Fennel API documentation: <https://fennel-lang.org/api>

### fnl-dir

(default: If `fnl/` directory exists at `vim.fn.stdpath('config')`, `"fnl"`;
otherwise, `"lua"`)

The relative path to `vim.fn.stdpath('config')` directory for your Fennel
runtime module files.\
It only supports `<fnl-dir>/?.fnl` and `<fnl-dir>/?/init.fnl` relative to
`vim.fn.stdpath('config')`.

> [!NOTE]
> 3rd-party plugins written in Fennel are supposed to be compiled to `lua/` as
> general nvim plugins written in Lua.

For the path management of macro files, see [macro-path](#macro-path).

### macro-path

(default:
`"./fnl/?.fnlm;./fnl/?/init.fnlm;./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"`)

The path patterns for `fennel.macro-path` to find Fennel macro module path.

Relative path markers (`./`) are internally copied and replaced with each
directory path on `&runtimepath`. (Feel free to skip over it, but the
replacements are optimized, filtered by the directories suffixed by `?` in this
option, e.g, with the default option value, `./` prefixes will be only replaced
with the paths that contains `fnl` directory on `&runtimepath`.)

Note: Unlike the `macro-path` option, `nvim-thyme` does _**not** provide any
option to modify `fennel.path`._ For Fennel runtime modules, `nvim-thyme` is
only designed to search through the path: `./fnl/?.fnl;./fnl/?/init.fnl` where
each `.` prefix represents the result path of `(vim.fn.stdpath :config)`.

### max-rollbacks

(default: `5`)

Keep the number of backups for rollback at most. Set `0` to disable it.

> [!NOTE]
> The rollback system only works for _**compile** error_;
> [nvim-thyme][nvim-thyme] does **not** provide any rollback system for nvim
> _**runtime** error._ Such a feature should be realized independently of a
> runtime compiler plugin.

### notifier

(default: `vim.notify`)

It is a function which takes the same arguments as `vim.notify`.

You can filter out specific notifications by this option. See
[.nvim-thyme.fnl.example][.nvim-thyme.fnl.example] for an example.

### command.compiler-options

(default: `nil`)

The default compiler-options for
[Fennel Wrapper Commands][Fennel Wrapper Commands] like [:Fnl][:Fnl]. If `nil`,
it inherits the values from [compiler-options](#compiler-options) above.

### command.cmd-history.method

(default: `"overwrite"`)

With [parinfer-rust][parinfer-rust] integration, the arguments for [:Fnl][:Fnl]
and [:FnlCompile][:FnlCompile] are modified before execution in Cmdline.

This option determines the command history behavior with the modified input.

Available methods:

- `"overwrite"`: Overwrite the original input with the modified input in the
  command history.
- `"append"`: Append the modified input to the command history in addition to
  the original input.
- `"ignore"`: Ignore the modified input. Just keep the original input.

### command.cmd-history.trailing-parens

(default: `"omit"`)

This option determines the behavior for
[Fennel Wrapper Commands][Fennel Wrapper Commands] like [:Fnl][:Fnl].

This option works only when [parinfer-rust][parinfer-rust] integration is
activated and [command.cmd-history.method][] is `"overwrite"` or `"append"`.

Available options:

- `"omit"`: Trim all the trailing parentheses in the command history.
- `"keep"`: Keep the trailing parentheses in the command history.

### watch.event

(default: `[:BufWritePost :FileChangedShellPost]`)

What [autocmd events][autocmd events] should check the changes of Fennel source
file.

Note that the watch system on autocmd events can only detect the changes on the
buffers loaded in current nvim session.

### watch.pattern

(default: `"*.{fnl,fnlm}"`)

The [autocmd pattern][autocmd pattern] for [match][autocmd-event-args] (path) to
check the changes of Fennel source file.

## Functions

### `thyme.loader`

The core function of [nvim-thyme][nvim-thyme]. The loader is to be appended to
[package.loaders] manually by user before loading any Fennel modules.

```lua
-- Wrapping the `require` in `function-end` is important for lazy-load.
table.insert(package.loaders, function(...)
  return require("thyme").loader(...) -- Make sure to `return` the result!
end)
```

> [!IMPORTANT]
> Before loading any Fennel module, you also have to prepend
> `/a/path/to/thyme/compile` which contains a substring `"/thyme/compile"` in
> `&runtimepath`, for example,
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
> You should manage all the options in [.nvim-thyme.fnl][.nvim-thyme.fnl]
> instead.

For the Lua ideom `require("thyme").setup()` in Fennel, the method call syntax
`(thyme:setup)` is supported. Therefore, the following weird syntax with `.` and
additional parentheses

```fennel
((require :thyme) (. :setup))
;; or
((-> (require :thyme) (. :setup)))
```

can be replaced by the following syntax with `:`

```fennel
(-> (require :thyme) (: :setup))
```

This function is to be called _after_ [VimEnter][VimEnter] wrapped in
[vim.schedule][vim.schedule], or later. For example,

```lua
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = vim.schedule_wrap(function()
    require("thyme").setup()
    require("others")
  end,
})
```

or if you carefully manage your config files where some Fennel file are loaded
in `vim.schedule` on `VimEnter` elsewhere, put the following code in such a
Fennel file:

```fennel
(-> (require :thyme)
    (: :setup))
```

### Functions at `thyme.fennel`

<!--
TODO: Describe every `thyme.fennel.<foobar>` functions?
-->

Provides a set of Fennel wrapper functions corresponding to
[Fennel Wrapper Commands][Fennel Wrapper Commands].

Unless otherwise noted, the functions named with `_` are equivalent to those
with `-`.

```vim
:= require("thyme").fennel
```

### Functions `pcall`-able

Some `thyme.call.<foo.bar.baz>`-modules are provided.

They are useful to call them without worrying about [thyme]'s validity, and
about the interface dependencies when you are considering another Fennel
compiler system.

#### `thyme.call.cache.clear`

Equivalent to [:ThymeCacheClear][:ThymeCacheClear], but it should work without
[thyme.setup].

This function is useful to be called on
[githooks](https://git-scm.com/docs/githooks) without worrying about [thyme]'s
validity, and about the interface dependencies when you were considering another
Fennel compiler system.

For example, add the following lines in `.githooks/post-checkout` with
executable permission:

```sh
if type nvim >/dev/null; then
  nvim --headless -c "lua pcall(require, 'thyme.call.cache.clear')" +q
fi
```

#### `thyme.call.cache.open`

Equivalent to [:ThymeCacheOpen][:ThymeCacheOpen], but it should work without
[thyme.setup].

### Keymaps

<!-- panvimdoc-include-comment
<Plug>(thyme-alternate-file)                *<Plug>(thyme-alternate-file)*
<Plug>(thyme-operator-echo-eval)            *<Plug>(thyme-operator-echo-eval)*
<Plug>(thyme-operator-echo-eval-compiler)   *<Plug>(thyme-operator-echo-eval-compiler)*
<Plug>(thyme-operator-echo-macrodebug)      *<Plug>(thyme-operator-echo-macrodebug)*
<Plug>(thyme-operator-echo-compile-string)  *<Plug>(thyme-operator-echo-compile-string)*
<Plug>(thyme-operator-print-eval)           *<Plug>(thyme-operator-print-eval)*
<Plug>(thyme-operator-print-eval-compiler)  *<Plug>(thyme-operator-print-eval-compiler)*
<Plug>(thyme-operator-print-macrodebug)     *<Plug>(thyme-operator-print-macrodebug)*
<Plug>(thyme-operator-print-compile-string) *<Plug>(thyme-operator-print-compile-string)
-->

The keymaps are defined with [thyme.setup][thyme.setup].

- `<Plug>(thyme-alternate-file)`\
  This is a keymap version of [:FnlAlternate][:FnlAlternate].

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

(Currently, the keymaps only supports the Fennel modules on
[&runtimepath][&runtimepath].)

## Commands

The commands are defined by [thyme.setup][thyme.setup].

### Fennel Wrapper Commands

#### :Fnl {fnl-expr}

Display the result of applying [fennel.eval][fennel.eval] to `{fnl-expr}`, but
respects your [&runtimepath][&runtimepath].

#### :FnlBuf [bufname]

Display the result of applying [fennel.dofile][fennel.dofile] but to
`[bufname]`, but respects your [&runtimepath][&runtimepath].

Without `[bufname]`, it evaluates the current buffer.

#### :FnlFile [file]

Display the result of applying [fennel.dofile][fennel.dofile] to `[file]`, but
respects your [&runtimepath][&runtimepath].

Without `[file]`, it evaluates the current file.

#### :FnlCompile {fnl-expr}

Almost equivalent to [:Fnl][:Fnl]. However, it does not evaluate the {fnl-expr},
but only returns the compiled lua results.

It does not affect the file system.

#### :FnlCompileBuf [bufname]

Almost equivalent to [:FnlBuf][:FnlBuf]. However, it does not evaluate the
[bufname] (or current buffer), but only returns the compiled lua results.

It does not affect the file system.

#### :FnlCompileFile [file]

Almost equivalent to [:FnlBuf][:FnlBuf]; however, it does not evaluate the
[file] (or current file), but only returns the compiled lua results.

It does not affect the file system.

<!-- panvimdoc-ignore-start -->
<!--
TODO: Add the spec tests first.

#### :FnlCompileFile[!] [src-file] [dest-file]

With `!`, it will write the compiled lua results to `[dest-file]`.
-->

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlCompileFile ~                                     *thyme-:FnlCompileFile*
-->

### Fennel Misc. Commands

<!-- panvimdoc-ignore-start -->

#### :FnlAlternate

Try to open the alternate file of current buffer:

- For a Fennel file, find the corresponding Lua file.
- For a Lua file, find the corresponding Fennel file.

This command will search in the following order:

1. The thyme's Lua caches
2. The directory of the target file
3. The corresponding `/fnl/` or `/lua/` directory

### Thyme General Commands

#### :ThymeUninstall

Remove all the cache, data, state, and log files, which are implicitly managed
by [nvim-thyme][nvim-thyme], and remove the hash of
[.nvim-thyme.fnl][.nvim-thyme.fnl] from the [trust][vim.secure.trust] database.

This command is so safe as it does **not** affect your
[.nvim-thyme.fnl][.nvim-thyme.fnl] and any of your configuration files.

When you have some issues with [nvim-thyme][nvim-thyme], try
[:ThymeCacheClear][:ThymeCacheClear] first. When the command does not resolve
your issue, then try this command [:ThymeUninstall][:ThymeUninstall].

### Thyme Config Commands

#### :ThymeConfigOpen

Open your [.nvim-thyme.fnl][.nvim-thyme.fnl] file.

### Thyme Cache Commands

#### :ThymeCacheClear

Clear all the Lua caches managed by [nvim-thyme][nvim-thyme].

If you failed to define the command [:ThymeCacheClear][:ThymeCacheClear] for
some reasons, please execute
[:lua require('thyme.call.cache.clear')](#thymecallcacheclear) manually in
Command line instead.

See also [:ThymeUninstall][:ThymeUninstall].

#### :ThymeCacheOpen

Open the root directory of the Lua caches managed by [nvim-thyme][nvim-thyme].

### Thyme Rollback Commands

Two concepts:

- Active backup: The backup to rollback if you fail to compile or evaluate a
  Fennel module at nvim runtime. You can switch to the active backup by
  [:ThymeRollbackSwitch][].

- Mounted backup: The backup to rollback regardless of your corresponding Fennel
  module stability. You can mount an active backup by [:ThymeRollbackMount][],
  or all the active backups by
  [:ThymeRollbackUnmountAll][:ThymeRollbackUnmountAll].

#### :ThymeRollbackSwitch {target}

Prompt to switch to the active backup of the `{target}`.

Any compile errors of the `{target}` of Fennel module will be rolled back to the
active backup.

Note that switching the active backup also affects the mounted backup of
`{target}`.

#### :ThymeRollbackMount {target}

Mount the active backup of the `{target}`.

Neovim will load the mounted backup instead of your module with the same name.
You should run [:ThymeRollbackUnmount][:ThymeRollbackUnmount] or
[:ThymeRollbackUnmountAll][:ThymeRollbackUnmountAll] to restore the mount state.

To select which backup to mount, use [:ThymeRollbackSwitch][].

#### :ThymeRollbackUnmount {target}

Unmount the mounted backups for the `{target}`.

#### :ThymeRollbackUnmountAll

Unmount the mounted backups.

[autocmd events]: https://neovim.io/doc/user/autocmd.html#autocmd-events
[autocmd pattern]: https://neovim.io/doc/user/autocmd.html#autocmd-pattern
[autocmd-event-args]: https://neovim.io/doc/user/api.html#event-args
[.nvim-thyme.fnl.example]: ../.nvim-thyme.fnl.example
[package.loaders]: https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
[VimEnter]: https://neovim.io/doc/user/autocmd.html#VimEnter
[vim.schedule]: https://neovim.io/doc/user/lua.html#vim.schedule()
[parinfer-rust]: https://github.com/eraserhd/parinfer-rust
[nvim-thyme]: https://github.com/aileot/nvim-thyme
[thyme]: https://github.com/aileot/nvim-thyme
[.nvim-thyme.fnl]: #options-in-nvim-thymefnl
[thyme.setup]: #thymesetup-or-thymesetup
[&runtimepath]: https://vim-jp.org/vimdoc-ja/options.html#'runtimepath'
[fennel.eval]: https://fennel-lang.org/api#evaluate-a-string-of-fennel
[fennel.dofile]: https://fennel-lang.org/api#evaluate-a-file-of-fennel
[Fennel Wrapper Commands]: #fennel-wrapper-commands
[:Fnl]: #fnl-fnl-expr
[:FnlBuf]: #fnlbuf-bufname
[:FnlCompile]: #fnlcompile-fnl-expr
[:FnlAlternate]: #fnlalternate
[:ThymeUninstall]: #thymeuninstall
[:ThymeCacheOpen]: #thymecacheopen
[:ThymeCacheClear]: #thymecacheclear
[:ThymeRollbackUnmount]: #thymerollbackunmount-target
[vim.secure.trust]: https://neovim.io/doc/user/lua.html#_lua-module:-vim.secure
[:ThymeRollbackUnmountAll]: #thymerollbackunmountall
