local _local_1_ = require("thyme.const")
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_fnl_file = _local_2_["assert-is-fnl-file"]
local read_file = _local_2_["read-file"]
local write_fnl_file_21 = _local_2_["write-fnl-file!"]
local cache = {["main-config"] = nil}
local function _3_(_, k)
  local _4_ = cache["main-config"][k]
  if (nil ~= _4_) then
    local val = _4_
    return val
  else
    local _0 = _4_
    return error(("unexpected option detected: " .. vim.inspect(k)))
  end
end
local _6_
if ("1" == vim.env.THYME_DEBUG) then
  local function _7_(_, k, v)
    cache["main-config"][k] = v
    return nil
  end
  _6_ = _7_
else
  local function _8_()
    return error("no option can be overridden by this table")
  end
  _6_ = _8_
end
cache["mt-config"] = setmetatable({}, {__index = _3_, __newindex = _6_})
local nvim_appname = vim.env.NVIM_APPNAME
local secure_nvim_env_3f = ((nil == nvim_appname) or ("" == nvim_appname))
local default_opts = {rollback = true, preproc = nil, ["compiler-options"] = {}, ["fnl-dir"] = "fnl", ["macro-path"] = table.concat({"./fnl/?.fnl", "./fnl/?/init-macros.fnl", "./fnl/?/init.fnl"}, ";")}
if not file_readable_3f(config_path) then
  local _10_ = vim.fn.confirm(("Missing \"%s\" at %s... Generate and open it?"):format(config_filename, vim.fn.stdpath("config")), "&No\n&yes", 1, "Warning")
  if (_10_ == 2) then
    local recommended_config = ";; recommended options of nvim-thyme\n{:rollback true\n :compiler-options {:correlate true\n                    ;; :compilerEnv _G\n                    :error-pinpoint [\"|>>\" \"<<|\"]}\n ;; The directory, in which you would manage your own Fennel modules, relative\n ;; to `(stdpath :config)`. The value only affects non-macro modules.\n :fnl-dir \"fnl\"\n ;; The path patterns for fennel.macro-path to find Fennel macro module path.\n ;; Relative path markers (`.`) are internally replaced with the paths on\n ;; &runtimepath filtered by the directories suffixed by `?`, e.g., `fnl/` in\n ;; `./fnl/?.fnl`.\n :macro-path \"./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl\"}"
    write_fnl_file_21(config_path, recommended_config)
    vim.cmd.tabedit(config_path)
    local function _11_()
      if (config_path == vim.api.nvim_buf_get_name(0)) then
        local _12_ = vim.fn.confirm("Trust this file? Otherwise, it will ask your trust again on nvim restart", "&Yes\n&no", 1, "Question")
        if (_12_ == 2) then
          return error(("abort trusting " .. config_path))
        else
          local _ = _12_
          return vim.cmd.trust()
        end
      else
        return nil
      end
    end
    vim.defer_fn(_11_, 800)
  else
    local _ = _10_
    error("abort proceeding with nvim-thyme")
  end
else
end
local function read_config(config_file_path)
  assert_is_fnl_file(config_file_path)
  local fennel = require("fennel")
  local config_code
  if secure_nvim_env_3f then
    config_code = read_file(config_file_path)
  else
    config_code = vim.secure.read(config_file_path)
  end
  local compiler_options = {["error-pinpoint"] = {"|>>", "<<|"}, filename = config_file_path}
  local _3fconfig = fennel.eval(config_code, compiler_options)
  local config_table = (_3fconfig or {})
  local config = vim.tbl_deep_extend("keep", config_table, default_opts)
  return config
end
local function get_config()
  if (nil == cache["main-config"]) then
    local main_config = read_config(config_path)
    cache["main-config"] = main_config
  else
  end
  return cache["mt-config"]
end
local function config_file_3f(path)
  return (config_filename == vim.fs.basename(path))
end
return {["get-config"] = get_config, ["config-file?"] = config_file_3f}
