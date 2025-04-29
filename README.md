<div align="center">

# 🕛 nvim-thyme

_Once compiled, **ZERO** overhead._

A runtime compiler for faster nvim startup. Faster!\
Not for pure lispers, but for the addicts to optimize nvim-startuptime who
still need a Fennel runtime compiler.

</div>

## Main Features

- Compile Fennel source just as a Lua failback.
- Get optimized with `vim.loader` out of box.
- Roll back to the last successfully compiled backup.

## Optional Features

The optional features can be enabled with few startup overhead.\
(For the details, please read the [Installation](#installation) guide below.)

- Recompile on autocmd events, tracking macro dependencies.
- Evaluate fennel code in `cmdline` and `keymap` with the following features:
  - Implicit paren-completions on [parinfer][].
  - Colorful output on [the builtin treesitter][].

## Motivation

To cut down startuptime, checking Fennel should be skipped at startup if
possible.
And I don't like to mess up `lua/` as I still write Lua when it seems to be
more suitable than Fennel. (Type annotation helps us very much.)
The project started from scratch. _Now in Beta!_

## Disclosure

- As you may have noticed, the term of _Zero overhead_ only means it does not
  affect startup time once compiled.
- As you may have noticed, the term of _JIT (Just-in-time)_ might be a bit
  misleading due to the convention.
  The _JIT_ in this project is more like JIT in
  [JIT Manufacturing](https://en.wikipedia.org/w/index.php?title=Just-in-time_manufacturing)
  than in
  [JIT Compilation](https://en.wikipedia.org/wiki/Just-in-time_compilation):
  it compiles missing modules, and optionally recompiles them on
  `BufWritePost`, etc.
- The _macro dependency tracker_ is based on the nature that module callstacks
  represent the dependencies of the modules as is. No `fennel.plugins`
  dependency!
- Clearing caches on `:FnlCacheClear!` does not actually delete cache files;
  instead, it _hides_ files to the [pool](./docs/reference.md#Pool)
  directory, and tries to restore the corresponding file in the pool if no
  contents are updated.
  This pool system is adopted here and there in this project.
  That prevents your SSD from wearing out
  though your modern SSD and OS might have optimized the file system already.

### Limitations

- `nvim-thyme` only support Lua/Fennel loader like `require`;
  it does not support Vim commands (e.g., `:source` and `:runtime`) to load your Fennel files.

## Requirements

- Neovim v0.10.0+
- [Fennel][] on your `&runtimepath`, in short, `&rtp`.
  (_not embedded_ unlike other plugins)
- `make` (or please locate a compiled `fennel.lua` in a `lua/` directory
  on `&rtp` by yourself)
- (Optional) a tree-sitter parser for fennel like [tree-sitter-fennel], or via
  [nvim-treesitter][] on `&rtp`.
- (Optional) [parinfer-rust][] on `&rtp`
  (to improve UX on the commands and keymaps)

## Installation

### 1. Ensure to Install Plugins (3 steps)

#### 1. Make sure to download, and add the path to `&runtimepath`

<details>
<summary>
It's recommended to define a <code>bootstrap</code> function for simplicity...

(The collapse shows a snippet for
<a href="https://github.com/folke/lazy.nvim">folke/lazy.nvim</a>.)

</summary>

```lua
local function bootstrap(name, url)
  -- To manage the version of repo, the path should be where your plugin manager will download it.
  local name = url:gsub("^.*/", "")
  local path = vim.fn.stdpath("data") .. "/lazy/" .. name
  if not vim.loop.fs_stat(path) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      url,
      path,
    })
  end
  vim.opt.runtimepath:prepend(path)
end
```

</details>

```lua
-- Given the `bootstrap` function defined above,
bootstrap("https://git.sr.ht/~technomancy/fennel")
bootstrap("https://github.com/aileot/nvim-thyme")
-- (Optional) Install your favorite plugin manager.
bootstrap("https://github.com/folke/lazy.nvim")
-- (Optional) Install some Fennel macro plugins before the setup of the plugin manager...
bootstrap("https://github.com/aileot/nvim-laurel")
```

#### 2. Add `require("thyme").loader` to `package.loaders`

```lua
-- Wrapping the `require` in `function-end` is important for lazy-load.
table.insert(package.loaders, function(...)
  return require("thyme").loader(...) -- Make sure to `return` the result!
end)
```

#### 3. Add a cache path for lua cache to `&runtimepath`

```lua
-- Note: Add a cache path to &rtp. The path MUST include `/thyme/`.
local thyme_cache_prefix = vim.fn.stdpath("cache") .. "/thyme/compiled"
vim.opt.rtp:prepend(thyme_cache_prefix)
-- Note: `vim.loader` internally cache &rtp, and recache it if modified.
-- Please test the best place to `vim.loader.enable()` by yourself.
vim.loader.enable() -- (optional) before the `bootstrap`s above, it could increase startuptime.
```

### 2. (Optional) Manage `nvim-thyme` with Plugin Manager

<!-- <details> -->
<!-- <summary> -->

With <a href="https://github.com/folke/lazy.nvim">folke/lazy.nvim</a>,

<!-- </summary> -->

```lua
{ "aileot/nvim-thyme",
  {
    version = "~v0.1.0",
    config = function()
      -- See the "Setup Optional Interfaces" section below!
    end,
  },
},
-- If you also manage macro plugin versions, please clear the Lua cache on the updates!
{ "aileot/nvim-laurel",
  {
    build = ":FnlCacheClear!",
    -- and other settings
  },
},
-- Optional dependency plugin.
{ "eraserhd/parinfer-rust",
  {
    build = "cargo build --release",
  },
},
```

(If you also manage macro plugin versions,
_please clear the Lua cache_ on the updates!
You can automate it either on spec hook like above,
on user event hook like below;
otherwise, please run `:FnlCacheClear!` manually.)

```lua
-- If you also manage macro plugin versions, please clear the Lua cache on the updates!
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate",
  command = "FnlCacheClear!",
})
```

<!-- </details> -->

### 3. Setup Optional Interfaces

To optimize the nvim startuptime, nvim-thyme suggests to define the Ex command
interfaces and its fnl file state checker some time
after `VimEnter` or `UIEnter`.
When to enable them is up to you. The following snippets are examples:

<details>
<summary>
If you're on lazy.nvim, define an autocmd.
</summary>

```lua
vim.api.nvim_create_autocmd("User", {
  once = true,
  pattern = "VeryLazy",
  callback = function()
    local thyme = require("thyme")
    thyme.watch_files() -- an autocmd wrapper of thyme.check_file
    thyme.define_commands()
  end,
})
```

</details>

<details open>
<summary>
Independently from lazy.nvim, define an autocmd.
</summary>

```lua
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function() -- You can substitute vim.schedule_wrap if you don't mind its tiny overhead.
    vim.schedule(function()
      local thyme = require("thyme")
      thyme.watch_files() -- an autocmd wrapper of thyme.check_file
      thyme.define_commands()
    end)
  end,
})
```

</details>

<details>
<summary>
Individually defines commands and autocmd to check.
</summary>

```lua
local id = vim.api.nvim_create_augroup("ThymeFoobar", {})
vim.api.nvim_create_autocmd({
  "CmdlineEnter",
  "CmdwinEnter",
}, {
  group = id,
  callback = function()
    require("thyme").define_commands()
  end,
})
vim.api.nvim_create_autocmd({
  "BufWritePost",
  "FileChangedShellPost",
}, {
  group = id,
  pattern = "*.fnl",
  callback = function(a)
    require("thyme").check_file(a.match)
  end,
})
```

</details>

### 4. Start `nvim`

If you don't have `.nvim-thyme.fnl` at `vim.fn.stdpath('config')`,
generally `$XDG_CONFIG_HOME/nvim`,
you will be asked to generate `.nvim-thyme.fnl` there with recommended config.

## Interfaces

This section lists out the interfaces with a summary.
For the details, please read the [Reference](./docs/REFERENCE.md).

### Options in `.nvim-thyme.fnl`

As described in the [Installation](#installation), all the settings of
`nvim-thyme` is set up with a config file `.nvim-thyme.fnl`;
no conventional `setup` function is provided by `nvim-thyme`.

Note: You don't have to prepare it by yourself!
If missing the config file, you will be asked to generate it with recommended
settings.

```fennel
{:rollback true
 :compiler-options {:correlate true
                    ;; :compilerEnv _G
                    :error-pinpoint ["|>>" "<<|"]}
 :fnl-dir "fnl"
 :macro-path "./fnl/?.fnlm;./fnl/?/init-macros.fnlm;./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"}
```

For performance, you can `bootstrap` _macro_ plugins inside `.nvim-thyme.fnl`
since, on missing a module written in Fennel, `.nvim-thyme.fnl` is always
loaded once a session of nvim. For example,

```fennel
(local root :/your/dir-path/to/install/plugins
(fn bootstrap! [url]
  ;; Note: How to extract name from url depends on what plugin manager you use.
  (let [name (url:gsub "^.*/" "")
        path (.. root "/" name)]
    (when (not (vim.uv.fs_stat path))
      (vim.notify (: "Install missing %s from %s..." :format name url)
                  vim.log.levels.WARN)
      (vim.fn.system [:git :clone "--filter=blob:none" url path])
      (vim.notify (: "%s is installed under %s." :format url path)))
    (vim.opt.rtp:prepend path)))

(bootstrap! "https://github.com/aileot/nvim-laurel")
{:rollback true
 :compiler-options {:correlate true
                    ;; :compilerEnv _G
                    :error-pinpoint ["|>>" "<<|"]}
 :macro-path "./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"}
```

### Functions

All the interfaces are provided from the "thyme" module: get them from
`require("thyme")`.

- [loader](./docs/reference.md#loader)
  is to be appended to `package.loaders`.
- [watch-files!](./docs/reference.md#watch-files!)
  or [watch_files](./docs/reference.md#watch_files)
  creates a set of autocmds to watch files.
- [define-keymaps!](./docs/reference.md#define-keymaps!)
  or [define_keymaps](./docs/reference.md#define_keymaps)
  defines a set of keymaps in the [list](#keymaps) below.
- [define-commands!](./docs/reference.md#define-commands!)
  or [define_commands](./docs/reference.md#define_commands)
  defines a set of command in the [list](#commands) below.

### Keymaps

The keymaps are defined with either `define_keymaps` or `define-keymaps!`.

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

### Commands

The commands are defined with either `define_commands` or `define-commands!`.
The following command list is an example defined by the functions,
with its default `cmd-prefix` option `Fnl`.

- `:Fnl` is an alias of `:FnlEval`.
  (It'll be undefined if `cmd-prefix` is an empty string.)
- `:FnlEval` evaluates its following Fennel expression.
- `:FnlCompileString` prints the Lua compiled results of its following Fennel expression.
- `:FnlCacheClear` clears Lua caches of Fennel files, and their dependency map logs.
- `:FnlConfigOpen` opens the config file `.nvim-thyme.fnl`.

## Migration Guide

### From hotpot.nvim

```lua
require("hotpot").setup({
  compiler = {
    macros = {
      env = "_COMPILER",
      correlate = true,
    },
    modules = {
      correlate = true,
    },
  },
})
```

```fennel
;; in .nvim-thyme.fnl at stdpath('config')
;; The thyme's searchers always set "_COMPILER" at "env" in evaluating macro modules.
{:compiler-options {:correlate true}
```

### From tangerine.nvim

```lua
require([[tangerine]]).setup({})
```

```fennel
;; in .nvim-thyme.fnl at stdpath('config')
{:compiler-options {:compilerEnv _G
                    :useBitLib true}
```

### From nfnl.nvim

1. Rename `lua/` at `vim.fn.stdpath('config')`,
   like`mv lua/ lua.bk/`.\
   Otherwise, there's some chances that nvim would unquestionably
   load lua files under the `lua/` directory apart from
   `nvim-thyme`.
2. Add codes to enable thyme's auto-compile system.
   See the [Installation](#installation) section above.
3. Start `nvim`. You will be asked to generate `.nvim-thyme.fnl` at the
   directory `vim.fn.stdpath('config')`.

## Ex Command Comparisons

Note: nvim-thyme only provides user commands when you call
[`thyme.define-commands!`](./docs/reference.md#define-commands!)
or
[`thyme.define_commands`](./docs/reference.md#define_commands)
for performance as described in [Commands](#commands) section above.

### Evaluate expression and print the result

```vim
" nvim-thyme
:Fnl (+ 1 1)
" hotpot.nvim
:Fnl= (+ 1 1)
" tangerine.nvim
:Fnl (print (+ 1 1))
```

### Evaluate expression without printing the result

```vim
" nvim-thyme
:silent Fnl (+ 1 1)
" hotpot.nvim
:Fnl (+ 1 1)
" tangerine.nvim
:Fnl (+ 1 1))
```

### Evaluate current file

```vim
" nvim-thyme
:FnlEvalFile %
" hotpot.nvim
:Fnlfile %
" tangerine.nvim
:FnlFile %:p
" nfnl.nvim
:NfnlFile (vim.fn.expand "%:p")
```

## Not in Plan

- Regardless of the nvim-plugin convention,
  `nvim-thyme` will _**not** provide a `setup` function._
  No matter how optimized a `setup` file is, searching a file
  (whether lua module or vim autoload)
  through `&rtp` would be inevitably the biggest cost.
- Unlike [tangerine.nvim][],
  `nvim-thyme` will _**not** compile `$XDG_CONFIG_HOME/nvim/init.fnl`._
- Unlike [hotpot.nvim][],
  `nvim-thyme` will _**not** load `plugin/*.fnl`, `ftplugin/*.fnl`, and so on._
- Unlike [nfnl][] and other compiler plugins,
  `nvim-thyme` will _**not** compile Fennel files which is not loaded in nvim
  runtime by default._
  If you still need to compile Fennel files in a project apart from nvim
  runtime, you have several options:
  - Define some `autocmd`s in your config or in .nvim.fnl.
  - Use another compiler plugin _together_ like [nfnl][].
  - Use a task runner like [overseer.nvim][].
  - Use git hooks.
    (See the [.githooks](,/.githooks) in this project as a WIP example. Help wanted.)

## Acknowledgement

Thanks to [Shougo](https://github.com/Shougo) for
[dein.vim](https://github.com/Shougo/dein.vim)
the legendary.
The design heavily inspires nvim-thyme.

Thanks to [harrygallagher4](https://github.com/harrygallagher4) for
[nvim-parinfer-rust][].
The integration of nvim-thyme with [parinfer][]
is based in part on copy extracted from the project,
so the [file](./fnl/thyme/api/parinfer.fnl) on parinfer is also
on the license [CC0-1.0](https://github.com/harrygallagher4/nvim-parinfer-rust/blob/34e2e5902399e4f1e75f4d83575caddb8154af26/LICENSE).

## Alternatives

- [aniseed][] provides Clojure-like interfaces. I've never used it.
- [hotpot.nvim][] loads fennel first. I've been indebted so long. Big thanks.
- [nfnl][] compiles to the `lua/`.
- [tangerine.nvim][] suggests to start the missing `init.fnl` from
  `plugin/`. Not in compiler sandbox.

[Fennel]: https://git.sr.ht/~technomancy/fennel
[aniseed]: https://github.com/Olical/aniseed
[nfnl]: https://github.com/Olical/nfnl
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
[tangerine.nvim]: https://github.com/udayvir-singh/tangerine.nvim
[parinfer]: https://shaunlebron.github.io/parinfer/
[parinfer-rust]: https://github.com/eraserhd/parinfer-rust
[nvim-parinfer-rust]: https://github.com/harrygallagher4/nvim-parinfer-rust
[the builtin treesitter]: https://neovim.io/doc/user/treesitter.html
[nvim-treesitter]: https://github.com/nvim-treesitter/nvim-treesitter
[tree-sitter-fennel]: https://github.com/alexmozaidze/tree-sitter-fennel
[overseer.nvim]: https://github.com/stevearc/overseer.nvim
