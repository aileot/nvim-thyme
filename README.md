<div align="center">

# 🕛 nvim-thyme

_Once compiled, **ZERO** overhead_\
A JIT compiler for nvim config, but no impact on nvim startup.

_Also welcome, **non-lispers**_\
who are tired to balance quotes and parentheses for handy tests in Cmdline
mode:\
How about trying **`:Fnl (vim.tbl_extend :force {:foo :bar} {:foo :qux`**
(_uh…, typos?_ ¯\\\_(ツ)\_/¯),\
or `:=vim.tbl_extend("force", {foo = "bar"}, {foo = "baz"})`?

[![badge/test][]][url/to/workflow/test] [![badge/semver][]][url/to/semver]
[![badge/license][]][url/to/license]\
[![badge/fennel][]][url/to/fennel]

<!--
NOTE: The colors come from the palette of catppuccin-mocha:
https://github.com/catppuccin/catppuccin/tree/v0.2.0?tab=readme-ov-file#-palettes
-->

[badge/test]: https://img.shields.io/github/actions/workflow/status/aileot/nvim-thyme/test.yml?branch=main&label=Test&logo=github&style=for-the-badge&logo=neovim&logoColor=CDD6F4&labelColor=1E1E2E&color=a6e3a1
[badge/semver]: https://img.shields.io/github/v/release/aileot/nvim-thyme?style=for-the-badge&logo=starship&logoColor=CDD6F4&labelColor=1E1E2E&&color=cdd6f4&include_prerelease&sort=semver
[badge/license]: https://img.shields.io/github/license/aileot/nvim-thyme?style=for-the-badge&logoColor=D9E0EE&labelColor=302D41&color=99d6ff
[badge/fennel]: https://img.shields.io/badge/Powered_by_Fennel-030281?&style=for-the-badge&logo=lua&logoColor=cdd6f4&label=Lua&labelColor=1E1E2E&color=cba6f7
[url/to/workflow/test]: https://github.com/aileot/nvim-thyme/actions/workflows/test.yml
[url/to/license]: ./LICENSE
[url/to/semver]: https://github.com/aileot/nvim-thyme/releases/latest
[url/to/fennel]: https://fennel-lang.org/

</div>

## ✨ Main Features

- Compile Fennel source just as Lua fallback **at nvim runtime**.
- Get optimized with `vim.loader` **out of box**.
- Safely **roll back** to the last successfully compiled backups if compilation
  fails.

## 🔌 Optional Features

The optional features can be enabled with few startup overhead thanks to
`vim.schedule`.\
(For the details, please read the [Installation][installation] guide below.)

- **Recompile** on autocmd events, tracking macro dependencies.
- Evaluate fennel code in `cmdline` and `keymap` with the following features:
  - Colorful output on [the builtin **treesitter**][builtin treesitter].
  - Implicit paren-completions on **[parinfer][parinfer]**: _Evaluate `(+ 1 2`
    as if `(+ 1 2)`!_

## 🔥 Motivations

- To cut down startuptime, checking Fennel should be skipped at startup if
  possible.
- I don't like to mess up `lua/` as I still write Lua when it seems to be more
  comfortable than Fennel. (Type annotation helps us very much.)

> [!TIP]
> Optionally, you can manage your Fennel files under `lua/` instead of `fnl/`
> directory. The relevant options are [fnl-dir][] and [macro-path][].

…and more features! So, this project started from scratch.

## ✔️ Requirements

- Neovim v0.11.1+
- [Fennel][Fennel] on your `&runtimepath`, in short, `&rtp`. (_not embedded_
  unlike [the alternative plugins][alternatives])
- `make` (or please locate a compiled `fennel.lua` in a `lua/` directory on
  `&rtp` by yourself)

### Optional Dependencies

- `luajit` or `lua5.1` (to compile `fennel` on `&rtp` on `make`)\
  If none of them is available, `nvim --clean --headless -l` will be used as a
  `lua` fallback.
- A tree-sitter parser for fennel like [tree-sitter-fennel], or via
  [nvim-treesitter][nvim-treesitter] on `&rtp`.
- The [parinfer-rust][parinfer-rust] on `&rtp` (to improve UX on the commands
  and keymaps)

## 🎉 Welcome Aboard

Welcome to the Neovim x Fennel community!

If you have never written Fennel before,
you can try Fennel on your favorite plugin manager!
For `lazy.nvim`,
add the following snippet to your specs
and play around with Fennel first.

(If you've decided to go along with Fennel, please skip to the [Installation][] section below.)

```lua
---@type LazySpec
{
  "aileot/nvim-thyme",
  version = "~v1.0.0",
  dependencies = {
    { "https://git.sr.ht/~technomancy/fennel" }
  },
  lazy = false,
  priority = 1000,
  build = ":lua require('thyme').setup(); vim.cmd('ThymeCacheClear')",
  init = function()
    -- Make your Fennel modules loadable.
    table.insert(package.loaders, function(...)
      return require("thyme").loader(...)
    end)
    local thyme_cache_prefix = vim.fn.stdpath("cache") .. "/thyme/compiled"
    vim.opt.rtp:prepend(thyme_cache_prefix)
  end,
  config = function()
    -- Create the helper interfaces.
    require("thyme").setup()
  end,
},
-- Optional
{
  "aileot/nvim-laurel",
  build = ":lua require('thyme').setup(); vim.cmd('ThymeCacheClear')",
},
{
  "eraserhd/parinfer-rust",
  build = "cargo build --release",
},
```

## 📦 Installation

### 1. Ensure to Install Plugins (3 steps)

#### 1. Make sure to download, and add the path to `&runtimepath`

<details>
<summary>
It's recommended to define a <code>bootstrap</code> function for simplicity…

(The collapse shows a snippet for
<a href="https://github.com/folke/lazy.nvim">folke/lazy.nvim</a>.)

</summary>

```lua
local function bootstrap(url)
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
-- Note: Add a cache path to &rtp. The path MUST include the literal substring "/thyme/compile".
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
{
  "aileot/nvim-thyme",
  version = "~v1.0.0",
  build = ":lua require('thyme').setup(); vim.cmd('ThymeCacheClear')",
  -- For config, see the "Setup Optional Interfaces" section
  -- and "Options in .nvim-thyme.fnl" below!
  -- config = function()
  -- end,
},
-- If you also manage macro plugin versions, please clear the Lua cache on the updates!
{
  "aileot/nvim-laurel",
  build = ":lua require('thyme').setup(); vim.cmd('ThymeCacheClear')",
  -- and other settings
},
-- Optional dependency plugin.
{
  "eraserhd/parinfer-rust",
  build = "cargo build --release",
},
```

(If you also manage macro plugin versions, _please clear the Lua cache_ on the
updates! You can automate it either on spec hook like above, on user event hook
like below; otherwise, please run `:ThymeCacheClear` manually.)

```lua
-- If you also manage macro plugin versions, please clear the Lua cache on the updates!
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate",
  command = "ThymeCacheClear",
})
```

<!-- </details> -->

### 3. Setup Optional Interfaces

To optimize the nvim startuptime, `nvim-thyme` suggests to define the Ex command
interfaces and its fnl file state checker some time after `VimEnter` or
`UIEnter`. When to enable them is up to you. The following snippets are
examples:

<details>
<summary>
If you're on lazy.nvim, define an autocmd.
</summary>

```lua
vim.api.nvim_create_autocmd("User", {
  once = true,
  pattern = "VeryLazy",
  callback = function()
    require("thyme").setup()
  end,
})
```

</details>

<details open>
<summary>
Independently from lazy.nvim, define an autocmd.
</summary>

```lua
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function() -- You can substitute vim.schedule_wrap if you don't mind its tiny overhead.
    vim.schedule(function()
      require("thyme").setup()
    end)
  end,
})
```

</details>

### 4. Start `nvim`

If you don't have `.nvim-thyme.fnl` at `vim.fn.stdpath('config')`, generally
`$XDG_CONFIG_HOME/nvim`, you will be asked to generate `.nvim-thyme.fnl` there
with recommended config. See the [Configuration][configuration] section below.

### 5. checkhealth

Ensure the setup by `:checkhealth thyme`.

## 📖 Interfaces

Please read the [reference][reference] for the details and additional features.

## ⚙️ Configuration

### Options in `.nvim-thyme.fnl`

All the configurations should be managed in a config file `.nvim-thyme.fnl`
instead of `thyme.setup`.

> [!NOTE]
> This is a point to optimize the nvim startuptime with the JIT compiler. Apart
> from `thyme.setup` but with `.nvim-thyme.fnl`, the configurations can be
> _lazily evaluated_ only by need.

Here is a sample config:

```fennel
{:max-rollback 5
 :compiler-options {:correlate true
                    ;; :compilerEnv _G
                    :error-pinpoint ["|>>" "<<|"]}
 :fnl-dir "fnl"
 :macro-path "./fnl/?.fnlm;./fnl/?/init-macros.fnlm;./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"}
```

However, _you don't have to prepare it by yourself!_

If `.nvim-thyme.fnl` is missing at `vim.fn.stdpath('config')` on nvim startup,
you will be asked for confirmation. Once you agree, a new `.nvim-thyme.fnl` will
be generated to `vim.fn.stdpath('config')` with recommended settings there. The
generated file is a copy of [.nvim-thyme.fnl.example][.nvim-thyme.fnl.example].

For all the available options, see the
[section](./docs/reference.md#options-in-nvim-thymefnl) in the reference.

<!--

NOTE: The tricks are incompatible with language servers like fennel-ls.

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

-->

## 🚚 Migration Guide

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

1. (_important_) Rename `lua/` at `vim.fn.stdpath('config')`,
   like`mv lua/ lua.bk/`.\
   Otherwise, there's some chances that nvim would unquestionably load lua files
   under the `lua/` directory apart from `nvim-thyme`.
2. Add codes to enable thyme's auto-compile system. See the
   [Installation][installation] section above.
3. Start `nvim`. You will be asked to generate `.nvim-thyme.fnl` at the
   directory `vim.fn.stdpath('config')`.

## 💥 Ex Command Comparisons

Note: `nvim-thyme` only provides user commands after you call
[`thyme.setup`](./docs/reference.md#thyme-setup--or--thyme-setup`) for
performance.

### Evaluate expression and print the result

With [parinfer-rust][parinfer-rust],

```vim
" nvim-thyme
:Fnl (+ 1 1
" hotpot.nvim
:Fnl= (+ 1 1)
" tangerine.nvim
:Fnl (print (+ 1 1))
```

### Evaluate expression without printing the result

```vim
" nvim-thyme
:silent Fnl (+ 1 1
" hotpot.nvim
:Fnl (+ 1 1)
" tangerine.nvim
:Fnl (+ 1 1)
```

### Evaluate current file

```vim
" nvim-thyme
:FnlFile %
" hotpot.nvim
:Fnlfile %
" tangerine.nvim
:FnlFile %:p
" nfnl.nvim
:NfnlFile (vim.fn.expand "%:p")
```

## 🕶️ Disclosure

<!--
TODO: Comment out once recompile strategy work on BufWritePost at macro files.
### Macro Dependency Tracking

- The _macro dependency tracker_ is based on the nature that
  the [call stack][] of a module represents the dependencies of the module as is.
  No `fennel.plugins` dependency!

[call stack]: https://en.wikipedia.org/wiki/Call_stack
-->

### Misleading…?

- As you may have noticed, the term of _Zero overhead_ only means it does not
  affect startup time once compiled at an nvim runtime.
- As you may have noticed, the term of _JIT (Just-in-time)_ might be a bit
  misleading due to the convention.\
  The _JIT_ in this project is more like JIT in
  [JIT Manufacturing](https://en.wikipedia.org/w/index.php?title=Just-in-time_manufacturing)
  than in
  [JIT Compilation](https://en.wikipedia.org/wiki/Just-in-time_compilation): it
  compiles missing modules, and optionally recompiles them on `BufWritePost` and
  `FileChangedShellPost`.

### Not in Plan

- Unlike [tangerine.nvim][tangerine.nvim], `nvim-thyme` does _**not** compile
  `$XDG_CONFIG_HOME/nvim/init.fnl`._
- Unlike [hotpot.nvim][hotpot.nvim], `nvim-thyme` does _**not** load_
  `plugin/*.fnl`, `ftplugin/*.fnl`, `lsp/*.fnl` and so on; `nvim-thyme` does
  _**not** support_ Vim commands (e.g., `:source` and `:runtime`) to load your
  Fennel files. `nvim-thyme` _**only** supports_ Lua/Fennel loader like
  `require`.
- Unlike [nfnl][nfnl], `nvim-thyme` does _**not** compile_ Fennel files which is
  not loaded in nvim runtime by default. If you still need to compile Fennel
  files in a project apart from nvim runtime, you have several options:
  - Define some `autocmd`s in your config or in .nvim.lua.
  - Use another compiler plugin _together_ like [nfnl][nfnl].
  - Use a task runner like [overseer.nvim][overseer.nvim].
  - Use git hooks. (See the [.githooks](./.githooks) in this project as a WIP
    example. Help wanted.)

## 📚 Acknowledgement

Thanks to [Shougo](https://github.com/Shougo) for
[dein.vim](https://github.com/Shougo/dein.vim) the legendary. The design heavily
inspires `nvim-thyme`.

Thanks to [harrygallagher4](https://github.com/harrygallagher4) for
[nvim-parinfer-rust][nvim-parinfer-rust]. The integration of `nvim-thyme` with
[parinfer][parinfer] is based in part on copy extracted from the project, so the
[file](./fnl/thyme/wrapper/parinfer.fnl) on `parinfer` is also on the license
[CC0-1.0](https://github.com/harrygallagher4/nvim-parinfer-rust/blob/34e2e5902399e4f1e75f4d83575caddb8154af26/LICENSE).

## 🤔 Alternatives

- [aniseed][aniseed] provides Clojure-like interfaces. I've never used it.
- [hotpot.nvim][hotpot.nvim] loads fennel first. I've been indebted so long. Big
  thanks.
- [nfnl][nfnl] compiles to the `lua/`.
- [tangerine.nvim][tangerine.nvim] suggests to start the missing `init.fnl` from
  `plugin/`. Not in compiler sandbox.

[alternatives]: #-alternatives
[installation]: #-installation
[configuration]: #%EF%B8%8F-configuration
[.nvim-thyme.fnl.example]: ./.nvim-thyme.fnl.example
[reference]: ./docs/reference.md
[fnl-dir]: ./docs/reference.md#fnl-dir
[macro-path]: ./docs/reference.md#macro-path
[Fennel]: https://git.sr.ht/~technomancy/fennel
[aniseed]: https://github.com/Olical/aniseed
[nfnl]: https://github.com/Olical/nfnl
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
[tangerine.nvim]: https://github.com/udayvir-singh/tangerine.nvim
[parinfer]: https://shaunlebron.github.io/parinfer/
[parinfer-rust]: https://github.com/eraserhd/parinfer-rust
[nvim-parinfer-rust]: https://github.com/harrygallagher4/nvim-parinfer-rust
[builtin treesitter]: https://neovim.io/doc/user/treesitter.html
[nvim-treesitter]: https://github.com/nvim-treesitter/nvim-treesitter
[tree-sitter-fennel]: https://github.com/alexmozaidze/tree-sitter-fennel
[overseer.nvim]: https://github.com/stevearc/overseer.nvim
