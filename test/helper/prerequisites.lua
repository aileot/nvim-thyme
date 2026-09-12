local deps = {
  "https://git.sr.ht/~technomancy/fennel",
  {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    build = ":lua require('nvim-treesitter.configs').setup({ sync_install = true, ensure_installed = { 'vim', 'fennel', 'lua' } })",
  },
  {
    "https://github.com/eraserhd/parinfer-rust",
    build = "cargo build --release",
  },
}

-- NOTE: Because this file is supposed to be `include`d, vim.fn.fnamemodify is
-- unsuitable.
assert(vim.env.REPO_ROOT, "$REPO_ROOT is NOT specified.")
local repo_root = vim.env.REPO_ROOT

do -- Assert test contexts.
  local function assert_is_under_repo(path)
    assert(
      vim.startswith(path, repo_root),
      path .. " is not under nvim-thyme repository."
    )
  end
  assert_is_under_repo(vim.fn.stdpath("config"))
  assert_is_under_repo(vim.fn.stdpath("cache"))
  assert_is_under_repo(vim.fn.stdpath("state"))
  assert_is_under_repo(vim.fn.stdpath("data"))
end

local uv = vim.uv or vim.loop
local on_windows = jit.os:lower() == "windows"

local function joinpath(...)
  local path_sep = on_windows and "\\" or "/"
  local result = table.concat({ ... }, path_sep)
  return result
end

local pack_dir = vim.env.DEPS_DIR
vim.fn.mkdir(pack_dir, "p")

---@param spec string|table string in url or {url, build?} the format would follow a simplified spec of lazy.nvim.
local function bootstrap(spec)
  local url = type(spec) == "string" and spec or spec[1]
  local name = url:match(".*/(.*)$")
  local path = joinpath(pack_dir, name)
  local was_installed = uv.fs_stat(path)
  if not was_installed then
    print("Installing " .. url .. " to " .. path)
    local out = vim.fn.system({
      "git",
      "clone",
      "--depth=1",
      "--filter=blob:none",
      url,
      path,
    })
    if vim.v.shell_error ~= 0 then
      vim.fn.delete(path, "rf")
      error(out)
      vim.cmd.cquit(vim.v.shell_error)
    end
  end
  assert(uv.fs_stat(path), path .. " does not exist.")
  vim.opt.rtp:prepend(path)
  if was_installed then
    return
  end
  if type(spec) == "table" and spec.build then
    if spec.build:sub(1, 1) == ":" then
      vim.cmd(spec.build)
    else
      print(spec.build)
      vim
        .system(vim.split(spec.build, " "), {
          cwd = path,
          stdout = function(err, data)
            if err then
              error(err)
            end
            vim.print(data)
          end,
        })
        :wait()
    end
  end
end

local function setup()
  vim.o.swapfile = false
  vim.o.writebackup = false
  vim.o.shortmess = "WF"

  -- NOTE: Treesitter parsers bundled with nvim can live outside $VIMRUNTIME
  -- (e.g. Nix keeps them in lib/nvim/parser). Collect them before the
  -- runtimepath is isolated below.
  local parser_sources = vim.api.nvim_get_runtime_file("parser/*.so", true)
  for _, dir in ipairs(vim.split(vim.env.THYME_PARSER_DIRS or "", ":", { plain = true })) do
    if dir ~= "" then
      vim.list_extend(parser_sources, vim.fn.glob(dir .. "/parser/*.so", false, true))
    end
  end
  -- NOTE: Last-resort fallback for read-only Nix runtimes that ship extra
  -- grammars (e.g. fennel) as /nix/store/*-tree-sitter-<lang>-*/parser.
  local extra_parsers = {}
  for _, lang in ipairs({ "vim", "fennel", "lua" }) do
    local present = false
    for _, src in ipairs(parser_sources) do
      if vim.fs.basename(src) == lang .. ".so" then
        present = true
        break
      end
    end
    if not present then
      local found = vim.fn.glob("/nix/store/*-tree-sitter-" .. lang .. "-*/parser", false, true)[1]
      if found and (uv.fs_stat(found) or {}).type == "file" then
        extra_parsers[lang] = found
      end
    end
  end

  vim.opt.runtimepath = {
    vim.fn.stdpath("config"),
    vim.env.VIMRUNTIME,
  }

  -- NOTE: Expose parsers from a writable directory on the isolated
  -- runtimepath. Tests that simulate a parser-less nvim do so by renaming
  -- this directory, which is impossible for read-only system runtimes.
  local parsers_dir = joinpath(pack_dir, "parsers")
  -- NOTE: `setup` runs once per spec, and each run appends `parsers_dir` to the
  -- runtimepath. Resolve symlinks to their real targets first so a later run
  -- does not collect the links it created last time and recreate them as
  -- self-referential loops.
  local parser_files = {}
  for _, src in ipairs(parser_sources) do
    local name = vim.fs.basename(src)
    parser_files[name] = uv.fs_realpath(src) or src
  end
  vim.fn.delete(joinpath(parsers_dir, "parser"), "rf")
  vim.fn.mkdir(joinpath(parsers_dir, "parser"), "p")
  local function link_parser(src, name)
    local dst = joinpath(parsers_dir, "parser", name)
    if src == dst then
      return
    end
    if not pcall(uv.fs_symlink, src, dst, {}) then
      pcall(uv.fs_copyfile, src, dst, {})
    end
  end
  for name, src in pairs(parser_files) do
    link_parser(src, name)
  end
  for lang, src in pairs(extra_parsers) do
    link_parser(src, lang .. ".so")
  end
  vim.opt.runtimepath:append(parsers_dir)

  vim.cmd("filetype off")
  vim.cmd("filetype plugin indent off")
  for _, spec in pairs(deps) do
    bootstrap(spec)
  end
  -- NOTE: nvim-treesitter >=1.0 keeps its runtime files (queries, etc.)
  -- under `runtime/`, which must be added to the runtimepath explicitly.
  local nvim_ts_runtime = joinpath(pack_dir, "nvim-treesitter", "runtime")
  if uv.fs_stat(nvim_ts_runtime) then
    vim.opt.runtimepath:prepend(nvim_ts_runtime)
  end
  local compile_dir = joinpath(vim.fn.stdpath("cache"), "thyme", "compile")
  vim.opt.rtp:prepend(compile_dir)
  vim.opt.rtp:prepend(repo_root)
  table.insert(package.loaders, function(...)
    return require("thyme").loader(...)
  end)
end

setup()

do -- A workaround to generate .nvim-thyme.fnl with recommended config.
  local raw_confirm = vim.fn.confirm
  vim.fn.confirm = function()
    local idx_yes = 2
    return idx_yes
  end
  local fallback = require("thyme.config.fallback")
  if fallback["should-fallback?"]() then
    fallback["prompt-fallback-config!"]()
  end
  vim.fn.confirm = raw_confirm
end
