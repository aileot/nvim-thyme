local deps = {
  "https://git.sr.ht/~technomancy/fennel",
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

local tmp_dir = vim.fn.stdpath("cache")
local test_dir = joinpath(tmp_dir, "thyme-tests")
local pack_dir = joinpath(test_dir, "deps")
vim.fn.mkdir(pack_dir, "p")

local function bootstrap(url)
  local name = url:match(".*/(.*)$")
  local path = joinpath(pack_dir, name)
  if not uv.fs_stat(path) then
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
      error(out)
    end
  end
  vim.opt.rtp:prepend(path)
end

local function setup()
  vim.o.swapfile = false
  vim.o.writebackup = false
  vim.o.runtimepath = vim.env.VIMRUNTIME
  vim.cmd("filetype off")
  vim.cmd("filetype plugin indent off")
  for _, url in ipairs(deps) do
    bootstrap(url)
  end
  local compile_dir = test_dir .. "/thyme/compile"
  vim.opt.rtp:prepend(compile_dir)
  vim.opt.rtp:prepend(repo_root)
  table.insert(package.loaders, function(...)
    require("thyme").loader(...)
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
