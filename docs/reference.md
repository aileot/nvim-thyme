# Reference

TODO

<!-- panvimdoc-ignore-start -->

## Options for `.nvim-thyme.fnl`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
options ~                                                     *thyme-options*
.nvim-thyme.fnl ~                                           *.nvim-thyme.fnl*
-->

### compiler-options

(default: `{}`)

The options to be passed to `fennel` functions which takes an `options` table
argument: `allowedGlobals`, `correlate`, `useMetadata`, and so on.

See the official Fennel API documentation: <https://fennel-lang.org/api>

### macro-path

(default: `"./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"`)

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

### `thyme.setup` or `thyme:setup`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
thyme.setup                                                     *thyme.setup*
thyme:setup                                                     *thyme:setup*
-->

Define [commands](#commands) and [keymaps](#keymaps).

It also defines an autocmd group `ThymeWatch` to keep compiled lua files
up-to-date.

> [!IMPORTANT]
> No arguments are allowed. You should manage all the options in [.nvim-thyme.fnl][] instead.

Both `(thyme.setup)` and `(thyme:setup)` work equivalent in Fennel.

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

```fennel
(vim.api.nvim_create_autocmd :VimEnter
  {:once true
   :callback #(-> (fn []
                    (-> (require :thyme)
                        (: :setup))
                    (require :others))
                  (vim.schedule))})
```

With [nvim-laurel][],

```fennel
(autocmd! :VimEnter * [:once]
          #(-> (fn []
                 (-> (require :thyme)
                     (: :setup))
                 (require :others))
               (vim.schedule)))
```

### Functions at `thyme.fennel`

Provides a set of Fennel wrapper functions
corresponding to [Fennel Wrapper Commands][].

Unless otherwise noted,
the functions named with `_` are equivalent to those with `-`.

```vim
:= require("thyme").fennel
```

## Functions `pcall`-able

Some `thyme.call.<foo.bar.baz>`-modules are provided.

They are useful to call them
without worrying about [thyme]'s validity,
and about the interface dependencies
when you are considering another Fennel compiler system.

### `thyme.call.cache.clear`

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

### `thyme.call.cache.open`

Equivalent to [:ThymeCacheOpen][], but it should work without [thyme.setup].

## Commands

The commands are defined by [thyme.setup][].

### Fennel Wrapper Commands

<!-- panvimdoc-ignore-start -->

#### `:FnlEval` (alias `:Fnl`)

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:Fnl ~                                                           *thyme-:Fnl*
:FnlEval ~                                                   *thyme-:FnlEval*
-->

Display the result of [fennel.eval][],
but respects your [&runtimepath][].

<!-- panvimdoc-ignore-start -->

#### `:FnlEvalFile {file}`

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
:FnlEvalFile ~                                           *thyme-:FnlEvalFile*
-->

Display the result of applying [fennel.dofile][] to {file},
but respects your [&runtimepath][].

#### `:FnlEvalBuffer`

TODO

#### `:FnlCompileString`

TODO

#### `:FnlCompileBuffer`

TODO

### Fennel Misc. Commands

#### `:FnlAlternate`

TODO

### Thyme General Command

#### `:ThymeUninstall`

Uninstall [nvim-thyme][].

This command remove all the cache, data, state, and log files,
which are implicitly managed by [nvim-thyme][].

When you have some issues with [nvim-thyme][],
try [:ThymeCacheClear][] first instead.
When the command does not resolve your issue,
then try this command [:ThymeUninstall][].

(This command is safe
since it does NOT affect your [.nvim-thyme.fnl][] and any of your configuration files.)

### Thyme Config Command

#### `:ThymeConfigOpen`

Open your [.nvim-thyme.fnl][] file.

### Thyme Cache Command

#### `:ThymeCacheClear`

Clear all the Lua caches managed by [nvim-thyme][].

If you failed to define the command [:ThymeCacheClear][] for some reasons,
please execute [:lua require('thyme.call.cache.clear')](#thyme-call-cache-clear)
manually in Command line instead.

#### `:ThymeCacheOpen`

Open the root directory of the Lua caches managed by [nvim-thyme][].

### Thyme Rollback Command

#### `:ThymeRollbackSwitch {target}`

Prompt to switch to the active backup of the {target}.

Any compile errors of the {target} of Fennel module will be rolled back to the active backup.
This switch also affects the mounted backup of {target}.

#### `:ThymeRollbackMount {target}`

Mount the active backup of the {target}.

Neovim will load the mounted backups instead of your modules with the same name.
You should run [:ThymeRollbackUnmount][] or [:ThymeRollbackUnmountAll][]
to restore the mount state.

#### `:ThymeRollbackUnmount {target}`

Unmount the mounted backups for the {target}.

#### `:ThymeRollbackUnmountAll`

Unmount all the mounted backups.

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
[:ThymeUninstall]: #thymeuninstall
[:ThymeCacheOpen]: #thymecacheopen
[:ThymeCacheClear]: #thymecacheclear
[:ThymeRollbackUnmount]: #thymerollbackunmount-target
[:ThymeRollbackUnmountAll]: #thymerollbackunmountall
