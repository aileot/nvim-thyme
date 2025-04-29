# Reference

TODO

## Terminology

### Pool

To prevent SSD from wearing out, `nvim-thyme` tries to delete and create files
_as few times_ as possible; instead, it tries to hide possibly outdated files
to the `pool` directory, and restore from the `pool` when the contents to be
written are the same as the corresponding files in the `pool`.

The `pool` directory is in `(.. (vim.fn.stdpath :state) "/thyme/pool")`:\
Try `:Fnl (vim.cmd.edit (.. (vim.fn.stdpath :state) "/thyme/pool")`.

## Options for `.nvim-thyme.fnl`

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

(default: `10`)

Keep the number of backups for rollback at most. Set `0` to disable it.

Note: Unlike the rollback system for compile error, `nvim-thyme` does
_**not** provide any rollback system for nvim **runtime** error._
Such a feature should be realized independently of a runtime compiler plugin.

## Functions

### `loader`

### `define-commands!`

### `define_commands`

### `define-keymaps!`

### `define_keymaps`

### `watch-files!`

### `watch_files`
