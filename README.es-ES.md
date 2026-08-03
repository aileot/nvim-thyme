

<div align="center">

# 🕛 nvim-thyme

**Compilador JIT de Fennel para Neovim sin sobrecarga**

_También bienvenidos, **los que no usan Lisp**_\
¿Qué tal probar **`:Fnl (vim.tbl_extend :force {:foo :bar} {:foo :qux`**
(_eh…, errores tipográficos?_ ¯\\\_(ツ)\_/¯),\
o `:=vim.tbl_extend("force", {foo = "bar"}, {foo = "baz"})`?

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

[**Bienvenido a bordo**](#-welcome-aboard)
•
[**Instalación**](#-installation)
•
[**Uso**](#-usage)
•
[**Referencia**](./docs/reference.md)
•
[**Preguntas Frecuentes**](#-faq)

</div>

## ✨ Características

- **Compilador JIT**:
  Compila el código fuente de fennel **_en tiempo de ejecución de nvim_**.
- **Reversiones (Rollbacks)**:
  Revierte de forma segura a las últimas copias de seguridad compiladas con éxito si la compilación
  falla.
- **Integraciones**:
  Evalúa código de fennel en `cmdline` y `keymap` con las siguientes características:
  - Salida con colores en [**treesitter** integrado][builtin treesitter].
  - Autocompletado implícito de paréntesis con **[parinfer][parinfer]**: _¡Evalúa `(+ 1 2`
    como si fuera `(+ 1 2)`!_

> [!CAUTION]
> Tenga en cuenta que las funciones no documentadas están sujetas a cambios sin previo aviso,
> independientemente de la [versión semántica][].

### 💥 Comparaciones

|                                      Característica |                                         nvim-thyme                                         |       hotpot.nvim        |   nfnl   | tangerine.nvim |
| -------------------------------------------: | :----------------------------------------------------------------------------------------: | :----------------------: | :------: | :------------: |
|                    **Cero** sobrecarga de inicio |                                             ✅                                             |            ❌            |    ✅    |       ❌       |
|                             Compilador **en tiempo de ejecución** |                                             ✅                                             |            ✅            |    ❌    |       ✅       |
|           _(Compilar en lua/<br> en tiempo de ejecución)_ |                                     ✅ <br> (opcional)                                     | ✅ <br> (con `:source`) |    ❌    |       ❌       |
|                         Reversiones **seguras** |                                             ✅                                             |            ❌            |    ❌    |       ❌       |
| **Integración con Parinfer**<br> en modo Cmdline |                                             ✅                                             |            ❌            |    ❌    |       ❌       |
|                            Dependencia de Fennel | **_No integrado_** <br> ([Cualquier versión compatible <br> debe estar en `&rtp`.][installation]) |         Integrado         | Integrado |    Integrado    |

Véase también
[Guía de Migración][migration-guide]
y
[Comparaciones de Comandos Ex][ex-command-comparisons]
a continuación.

## 🔥 Motivaciones

- Para reducir el tiempo de inicio, la verificación de Fennel debería omitirse al arrancar si
  es posible.
- No me gusta ensuciar `lua/` ya que sigo escribiendo Lua cuando parece más cómodo que Fennel. (Las anotaciones de tipo nos ayudan mucho.)

> [!TIP]
> Opcionalmente, puedes gestionar tus archivos de Fennel bajo `lua/` en lugar del directorio
> `fnl/`. Las opciones relevantes son [fnl-dir][] y [macro-path][].

…and más características! Por eso, este proyecto comenzó desde cero.

## ✔️ Requisitos

- Neovim v0.11.1+
- [Fennel][Fennel] en tu [`&runtimepath`][&runtimepath],
  en resumen, [`&rtp`][&runtimepath].\
  (_no integrado_, a diferencia de [los plugins alternativos][comparisons]. Consulta la [Instalación][installation].)
- `make`
  (o localiza tú mismo un `fennel.lua` compilado
  en un directorio `lua/` en `&rtp`)

### Dependencias opcionales

- `luajit` o `lua5.1`
  (para compilar `fennel` en `&rtp` con `make`)\
  Si ninguno está disponible,
  `nvim --clean --headless -l` se usará como alternativa para `lua`.
- Un analizador tree-sitter para fennel como [tree-sitter-fennel],
  o mediante [nvim-treesitter][nvim-treesitter] en `&rtp`.
- [parinfer-rust][parinfer-rust] en `&rtp`
  (para mejorar la experiencia de usuario en los comandos y atajos de teclado)

## 🎉 Welcome Aboard

1. Instala `nvim-thyme` con [lazy.nvim][].

(Si has decidido continuar con Fennel, pasa directamente a la sección de [Instalación][] a continuación.)

```lua
require("lazy").setup({
  ---@type LazySpec
  {
    "aileot/nvim-thyme",
    version = "^v1.6.0",
    dependencies = {
      { "https://git.sr.ht/~technomancy/fennel" },
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
  -- and other plugin specs...
})
```

> [!WARNING]
> Con la configuración anterior,
> no podrás cargar módulos de Fennel _antes_ de la configuración de `lazy.nvim`,
> sino solo _después_ de que se complete la configuración de `init`.
> Sigue la sección de [Instalación][] a continuación si quieres escribir más en Fennel.

### 2. Prueba las características interactivas en Cmdline

```vim
:Fnl (+ 1 2 3) " Evaluate Fennel expression
:Fnl (vim.notify "Hello, Fennel!") " Call nvim APIs
:FnlBuf % " Evaluate Fennel expression in the current buffer
```

## 📦 Instalación

### 1. Asegúrate de instalar los plugins (3 pasos)

#### 1. Asegúrate de descargar y agregar la ruta a `&runtimepath`

<details>
<summary>
Se recomienda definir una función <code>bootstrap</code> por simplicidad…

(El desplegable muestra un fragmento para
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

#### 2. Agrega `require("thyme").loader` a `package.loaders`

```lua
-- Wrapping the `require` in `function-end` is important for lazy-load.
table.insert(package.loaders, function(...)
  return require("thyme").loader(...) -- Make sure to `return` the result!
end)
```

#### 3. Agrega una ruta de caché para lua cache a `&runtimepath`

```lua
-- Note: Add a cache path to &rtp. The path MUST include the literal substring "/thyme/compile".
local thyme_cache_prefix = vim.fn.stdpath("cache") .. "/thyme/compiled"
vim.opt.rtp:prepend(thyme_cache_prefix)
-- Note: `vim.loader` internally cache &rtp, and recache it if modified.
-- Please test the best place to `vim.loader.enable()` by yourself.
vim.loader.enable() -- (optional) before the `bootstrap`s above, it could increase startuptime.
```

### 2. (Opcional) Gestiona `nvim-thyme` con un Plugin Manager

<!--
NOTE: GFM callouts are invalid in <details>.
-->

> [!CAUTION]
> Asegúrate de deshabilitar la opción `performance.rtp.reset` de `lazy.nvim`. (La opción está habilitada por defecto.)
> De lo contrario, te encontrarás con un "loop or previous error" o te indicará que falta la subcadena literal `"/thyme/compile"` en
> `&runtimepath`.

<details open>
<summary>
Con <a href="https://github.com/folke/lazy.nvim">folke/lazy.nvim</a>,
</summary>

```lua
require("lazy").setup({
  spec = {
    {
      "aileot/nvim-thyme",
      version = "^v1.6.0",
      dependencies = {
        { "https://git.sr.ht/~technomancy/fennel" },
      },
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
    -- and other plugin specs...
  },
  performance = {
    rtp = {
      reset = false, -- Important! It's unfortunately incompatible with nvim-thyme.
    },
  },
})
```

(Si también gestionas versiones de plugins de macros, _limpia la caché de Lua_ en las
actualizaciones. Puedes automatizarlo en el hook de spec como arriba, en el hook de evento de usuario
como abajo; de lo contrario, ejecuta `:ThymeCacheClear` manualmente.)

```lua
-- If you also manage other Fennel macro plugin versions, please clear the Lua cache on the updates!
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate", -- for lazy.nvim
  callback = function()
    require("thyme").setup()
    vim.cmd("ThymeCacheClear")
  end,
})
```

</details>

### 3. Configuración de interfaces opcionales

Para optimizar el tiempo de inicio de nvim, `nvim-thyme` sugiere definir las interfaces de comandos Ex y su verificador de estado de archivos fnl algún tiempo después de `VimEnter`. Por ejemplo,

```lua
-- In init.lua,
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function() -- You can substitute vim.schedule_wrap if you don't mind its tiny overhead.
    vim.schedule(function()
      require("thyme").setup()
    end)
  end,
})
```

### 4. Inicia `nvim`

Si no tienes `.nvim-thyme.fnl` en `vim.fn.stdpath('config')`, generalmente
`$XDG_CONFIG_HOME/nvim`, se te pedirá que lo generes allí con la configuración recomendada. Consulta la sección de [Configuración][configuration] a continuación.

### 5. checkhealth

Verifica la configuración con `:checkhealth thyme`.

## 🚀 Uso

Lee la [referencia][reference] para más detalles y características adicionales.

## ⚙️ Configuración

### Opciones en `.nvim-thyme.fnl`

`nvim-thyme` gestiona todas las configuraciones en un archivo de configuración separado `.nvim-thyme.fnl`
en lugar de `thyme.setup`.

> [!NOTE]
> Esto se debe a un punto para optimizar el tiempo de inicio de nvim con el compilador JIT. Aparte
> de `thyme.setup` y con `.nvim-thyme.fnl`, las configuraciones pueden ser _evaluadas de forma diferida (lazy)_ solo según sea necesario.

Aquí hay un ejemplo de configuración:

```fennel
{:max-rollback 5
 :compiler-options {:correlate true
                    ;; :compilerEnv _G
                    :error-pinpoint ["|>>" "<<|"]}
 :fnl-dir "fnl"
 :macro-path "./fnl/?.fnlm;./fnl/?/init-macros.fnlm;./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"}
```

Sin embargo, _¡no tienes que prepararlo tú mismo!_

Si `.nvim-thyme.fnl` falta en `vim.fn.stdpath('config')` al iniciar nvim,
se te pedirá confirmación. Una vez que aceptes, se generará un nuevo `.nvim-thyme.fnl` en
`vim.fn.stdpath('config')` con la configuración recomendada. El
archivo generado es una copia de [.nvim-thyme.fnl.example][.nvim-thyme.fnl.example].

Para todas las opciones disponibles, consulta
[Opciones](./docs/reference.md#options-in-nvim-thymefnl) en la referencia.

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

## 🚚 Guía de Migración

### Desde hotpot.nvim

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

### Desde nfnl.nvim

1. (_importante_) Renombra `lua/` en `vim.fn.stdpath('config')`,
   por ejemplo `mv lua/ lua.bk/`.\
   De lo contrario, existe la posibilidad de que nvim cargue incondicionalmente los archivos lua
   dentro del directorio `lua/` además de `nvim-thyme`.
2. Agrega el código para habilitar el sistema de auto-compilación de thyme. Consulta la
   sección de [Instalación][installation] anterior.
3. Inicia `nvim`. Se te pedirá que generes `.nvim-thyme.fnl` en el
   directorio `vim.fn.stdpath('config')`.

### Desde tangerine.nvim

```lua
require([[tangerine]]).setup({})
```

```fennel
;; in .nvim-thyme.fnl at stdpath('config')
{:compiler-options {:compilerEnv _G
                    :useBitLib true}
```

## 🍿 Comparaciones de Comandos Ex

Nota: `nvim-thyme` solo proporciona comandos de usuario después de que llames a
[`thyme.setup`](./docs/reference.md#thyme-setup--or--thyme-setup`) por
rendimiento.

### Evaluar expresión e imprimir el resultado

Con [parinfer-rust][parinfer-rust],

```vim
" nvim-thyme
:Fnl (+ 1 1
" hotpot.nvim
:Fnl= (+ 1 1)
" tangerine.nvim
:Fnl (print (+ 1 1))
```

### Evaluar expresión sin imprimir el resultado

```vim
" nvim-thyme
:silent Fnl (+ 1 1
" hotpot.nvim
:Fnl (+ 1 1)
" tangerine.nvim
:Fnl (+ 1 1)
```

### Evaluar el archivo actual

```vim
" nvim-thyme
:FnlFile %
" hotpot.nvim
:Fnlfile %
" nfnl.nvim
:NfnlFile (vim.fn.expand "%:p")
" tangerine.nvim
:FnlFile %:p
```

### No está en los planes

- A diferencia de [tangerine.nvim][tangerine.nvim], `nvim-thyme` _**no** compila
  `$XDG_CONFIG_HOME/nvim/init.fnl`._
- A diferencia de [hotpot.nvim][hotpot.nvim], `nvim-thyme` _**no carga**_
  `plugin/*.fnl`, `ftplugin/*.fnl`, `lsp/*.fnl` y similares; `nvim-thyme` _**no soporta**_ comandos de Vim (p. ej., `:source` y `:runtime`) para cargar tus
  archivos de Fennel. `nvim-thyme` _**solo soporta**_ el cargador de Lua/Fennel como
  `require`.
- A diferencia de [nfnl][nfnl], `nvim-thyme` _**no compila**_ archivos de Fennel que
  no se cargan en el tiempo de ejecución de nvim por defecto. Si aún necesitas compilar archivos de Fennel
  en un proyecto aparte del tiempo de ejecución de nvim, tienes varias opciones:
  - Define algunos `autocmd`s en tu configuración o en .nvim.lua.
  - Usa otro plugin de compilación _junto con él_ como [nfnl][nfnl].
  - Usa un ejecutor de tareas como [overseer.nvim][overseer.nvim].
  - Usa hooks de git. (Consulta [.githooks](./.githooks) en este proyecto como un ejemplo en progreso.
    Se agradece ayuda.)

## 🕶️ Aclaraciones

<!--
TODO: Comment out once recompile strategy work on BufWritePost at macro files.
### Macro Dependency Tracking

- The _macro dependency tracker_ is based on the nature that
  the [call stack][] of a module represents the dependencies of the module as is.
  No `fennel.plugins` dependency!

[call stack]: https://en.wikipedia.org/wiki/Call_stack
-->

### ¿Engañoso…?

- Como habrás notado, el término _Cero sobrecarga_ solo significa que no
  afecta el tiempo de inicio una vez compilado en el tiempo de ejecución de nvim.
- Como habrás notado, el término _JIT (Just-in-time)_ podría ser un poco
  engañoso debido a la convención.\
  El _JIT_ en este proyecto se parece más al JIT de
  [Fabricación JIT](https://en.wikipedia.org/w/index.php?title=Just-in-time_manufacturing)
  que a
  [Compilación JIT](https://en.wikipedia.org/wiki/Just-in-time_compilation): compila
  módulos faltantes y, opcionalmente, los recompila en `BufWritePost` y
  `FileChangedShellPost`.

## ❓ Preguntas Frecuentes (FAQ)

### P. ¿Es compatible con `vim.loader`?

R. Sí, lo es. `vim.loader.enable()` optimiza el cargador de `nvim-thyme`.

### P: "loop or previous error"?

R. `nvim-thyme` es incompatible con la opción `performance.rtp.reset` de [lazy.nvim][].

Asegúrate de haber deshabilitado la opción `performance.rtp.reset` de lazy.nvim.
(La opción está habilitada por defecto.)

### P. ¿Puedo deshabilitar parinfer para editar búferes, manteniéndolo habilitado en la integración de Cmdline?

R. Sí, puedes. Simplemente establece la variable `vim.g.parinfer_enabled` en `false`.

### P. ¿El sistema de rollback me ayuda a evitar iniciar nvim prácticamente sin configuraciones por algunas malas configuraciones?

R. Sí, pero solo para los módulos escritos en Fennel.

Los rollbacks se aplican automáticamente cuando se detectan errores en tiempo de _compilación_.
Además de eso, con las combinaciones de [:ThymeRollbackSwitch][] y [:ThymeRollbackMount][],
también puedes revertir errores de _tiempo de ejecución_ en Lua compilado.

Sin embargo, se recomienda poner tus archivos de configuración bajo control de git primero
por si `nvim` llega a fallar incluso antes de llegar a las líneas que definen los comandos de ayuda de rollback.

### P. ¿Cómo puedo mezclar configuración de Fennel con configuración de Lua en un directorio?

R. Por defecto, o con la [configuración recomendada][.nvim-thyme.fnl.example],
`nvim-thyme` hará que `nvim` cargue módulos de Fennel en el directorio `lua/`
de la misma manera que el `nvim` por defecto carga los otros módulos de Lua
a menos que `fnl/` exista en el directorio que `stdpath("config")` devuelve (generalmente `~/.config/nvim`).

Ten en cuenta que, si tanto `foo.lua` como `foo.fnl` existen en el directorio `lua/`, siempre se carga `foo.lua`.

Las opciones relevantes son solo [fnl-dir][] y [macro-path][].

<details>
<summary>
El desplegable ilustra cómo fusionar `fnl/` en el directorio `lua/` de la manera más segura posible.
</summary>

(Supongamos que tus archivos de configuración de `nvim` están gestionados por `git`, en `~/.config/nvim`.)

```sh
# Commit current status
git add -A
git commit -m 'save states before merging fnl/ into lua/'
# Note the current branch name (main or master, maybe)
git branch --show-current
# Create and switch a new branch. (The branch name is an example.)
git switch -c merge-fnl-into-lua
cd ~/.config/nvim
# Check the results with `--dry-run`.
git mv --dry-run fnl lua
git mv --verbose fnl lua
# Make sure your nvim can start without issues.
nvim
```

Si tienes algún problema,
restablece a los estados anteriores donde `fnl/` y `lua/` coexistían
con el siguiente comando.

```sh
# Assume your default branch is `main`.
git reset --hard main
git switch main
# Put aside the previous cache directory.
mv ~/.cache/nvim/thyme{,.bk}
```

</details>

## 📚 Agradecimientos

Gracias a [Shougo](https://github.com/Shougo) por
el legendario [dein.vim](https://github.com/Shougo/dein.vim). El diseño inspira
enormemente a `nvim-thyme`.

Gracias a [harrygallagher4](https://github.com/harrygallagher4) por
[nvim-parinfer-rust][nvim-parinfer-rust]. La integración de `nvim-thyme` con
[parinfer][parinfer] se basa en parte en código extraído del proyecto, por lo que el
[archivo](./fnl/thyme/wrapper/parinfer.fnl) sobre `parinfer` también está bajo la licencia
[CC0-1.0](https://github.com/harrygallagher4/nvim-parinfer-rust/blob/34e2e5902399e4f1e75f4d83575caddb8154af26/LICENSE).

[.nvim-thyme.fnl.example]: ./.nvim-thyme.fnl.example
[:ThymeRollbackMount]: ./docs/reference.md#thymerollbackmount-target
[:ThymeRollbackSwitch]: ./docs/reference.md#thymerollbackswitch-target
[Fennel]: https://git.sr.ht/~technomancy/fennel
[comparisons]: #-comparisons
[aniseed]: https://github.com/Olical/aniseed
[builtin treesitter]: https://neovim.io/doc/user/treesitter.html
[configuration]: #%EF%B8%8F-configuration
[fnl-dir]: ./docs/reference.md#fnl-dir
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
[installation]: #-installation
[migration-guide]: #-migration-guide
[ex-command-comparisons]: #-ex-command-comparisons
[lazy.nvim]: https://github.com/folke/lazy.nvim
[macro-path]: ./docs/reference.md#macro-path
[nfnl]: https://github.com/Olical/nfnl
[nvim-parinfer-rust]: https://github.com/harrygallagher4/nvim-parinfer-rust
[nvim-treesitter]: https://github.com/nvim-treesitter/nvim-treesitter
[overseer.nvim]: https://github.com/stevearc/overseer.nvim
[parinfer-rust]: https://github.com/eraserhd/parinfer-rust
[parinfer]: https://shaunlebron.github.io/parinfer/
[reference]: ./docs/reference.md
[semantic versioning]: https://semver.org/
[tangerine.nvim]: https://github.com/udayvir-singh/tangerine.nvim
[tree-sitter-fennel]: https://github.com/alexmozaidze/tree-sitter-fennel
[watch.strategy]: ./docs/reference.md#watchstrategy
[&runtimepath]: https://vim-jp.org/vimdoc-en/options.html#'runtimepath'
