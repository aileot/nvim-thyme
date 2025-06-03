local deps = {
  "https://git.sr.ht/~technomancy/fennel",
  {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    build = ":lua require('nvim-treesitter.configs').setup({ sync_install = true, ensure_installed = { 'vim', 'fennel', 'lua' } })",
  },
  { "https://github.com/eraserhd/parinfer-rust", build = "cargo build --release" },
}

-- NOTE: Because this file is supposed to be `include`d, vim.fn.fnamemodify is
-- unsuitable.
assert(vim.env.REPO_ROOT, "$REPO_ROOT is NOT specified.")
local repo_root = vim.env.REPO_ROOT

do -- Assert test contexts.
  local function assert_is_under_repo(path)
    assert(vim.startswith(path, repo_root), path .. " is not under nvim-thyme repository.")
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
  vim.opt.runtimepath = {
    vim.fn.stdpath("config"),
    vim.env.VIMRUNTIME,
  }
  vim.cmd("filetype off")
  vim.cmd("filetype plugin indent off")
  for _, spec in pairs(deps) do
    bootstrap(spec)
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
  require("thyme.config")
  vim.fn.confirm = raw_confirm
end
