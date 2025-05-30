local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_fnl_file = _local_2_["assert-is-fnl-file"]
local read_file = _local_2_["read-file"]
local write_fnl_file_21 = _local_2_["write-fnl-file!"]
local nvim_appname = vim.env.NVIM_APPNAME
local secure_nvim_env_3f = ((nil == nvim_appname) or ("" == nvim_appname))
local std_config = vim.fn.stdpath("config")
local std_fnl_dir_3f = vim.uv.fs_stat(vim.fs.joinpath(std_config, "fnl"))
local use_lua_dir_3f = not std_fnl_dir_3f
local default_opts
local _3_
if use_lua_dir_3f then
  _3_ = "lua"
else
  _3_ = "fnl"
end
local _5_
if use_lua_dir_3f then
  _5_ = (std_config .. "/lua/?.fnlm")
else
  _5_ = nil
end
local _7_
if use_lua_dir_3f then
  _7_ = (std_config .. "/lua/?/init.fnlm")
else
  _7_ = nil
end
local _9_
if use_lua_dir_3f then
  _9_ = (std_config .. "/lua/?.fnl")
else
  _9_ = nil
end
local _11_
if use_lua_dir_3f then
  _11_ = (std_config .. "/lua/?/init-macros.fnl")
else
  _11_ = nil
end
local function _13_(...)
  if use_lua_dir_3f then
    return (std_config .. "/lua/?/init.fnl")
  else
    return nil
  end
end
local function _14_(_241)
  return _241
end
default_opts = {["max-rollbacks"] = 5, ["compiler-options"] = {}, ["fnl-dir"] = _3_, ["macro-path"] = table.concat({"./fnl/?.fnlm", "./fnl/?/init.fnlm", "./fnl/?.fnl", "./fnl/?/init-macros.fnl", "./fnl/?/init.fnl", _5_, _7_, _9_, _11_, _13_(...)}, ";"), preproc = _14_, notifier = vim.notify, command = {["compiler-options"] = nil, ["cmd-history"] = {method = "overwrite", ["trailing-parens"] = "omit"}}, keymap = {["compiler-options"] = nil, mappings = {}}, watch = {event = {"BufWritePost", "FileChangedShellPost"}, pattern = "*.{fnl,fnlm}", strategy = "clear-all", ["macro-strategy"] = "clear-all"}, ["dropin-paren"] = {["cmdline-completion-key"] = false, ["cmdline-key"] = false}}
local cache = {}
if not file_readable_3f(config_path) then
  local _15_ = vim.fn.confirm(("Missing \"%s\" at %s. Generate and open it?"):format(config_filename, vim.fn.stdpath("config")), "&No\n&yes", 1, "Warning")
  if (_15_ == 2) then
    local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
    local example_config_filename = (config_filename .. ".example")
    local _let_16_ = vim.fs.find(example_config_filename, {upward = true, type = "file", path = this_dir})
    local example_config_path = _let_16_[1]
    local recommended_config = read_file(example_config_path)
    write_fnl_file_21(config_path, recommended_config)
    vim.cmd(("tabedit " .. config_path))
    local function _17_()
      return (config_path == vim.api.nvim_buf_get_name(0))
    end
    vim.wait(1000, _17_)
    vim.cmd("redraw!")
    if (config_path == vim.api.nvim_buf_get_name(0)) then
      local _18_ = vim.fn.confirm("Trust this file? Otherwise, it will ask your trust again on nvim restart", "&Yes\n&no", 1, "Question")
      if (_18_ == 2) then
        local buf_name = vim.api.nvim_buf_get_name(0)
        assert((config_path == buf_name), ("expected %s, got %s"):format(config_path, buf_name))
        vim.cmd("trust")
      else
        local _ = _18_
        vim.secure.trust({action = "remove", path = config_path})
        local _19_ = vim.fn.confirm(("Aborted trusting %s. Exit?"):format(config_path), "&No\n&yes", 1, "WarningMsg")
        if (_19_ == 2) then
          os.exit(1)
        else
        end
      end
    else
    end
  else
    local _ = _15_
    local _23_ = vim.fn.confirm("Aborted proceeding with nvim-thyme. Exit?", "&No\n&yes", 1, "WarningMsg")
    if (_23_ == 2) then
      os.exit(1)
    else
    end
  end
else
end
local _local_27_ = require("thyme.util.trust")
local denied_3f = _local_27_["denied?"]
local RollbackManager = require("thyme.rollback.manager")
local ConfigRollbackManager = RollbackManager.new("config", ".fnl")
local function notify_once_21(msg, ...)
  return vim.notify_once(("thyme(config): " .. msg), ...)
end
local function read_config_with_backup_21(config_file_path)
  assert_is_fnl_file(config_file_path)
  local fennel = require("fennel")
  local backup_name = "default"
  local backup_handler = ConfigRollbackManager["backup-handler-of"](ConfigRollbackManager, backup_name)
  local mounted_backup_path = backup_handler["determine-mounted-backup-path"](backup_handler)
  local _3fconfig_code
  if file_readable_3f(mounted_backup_path) then
    local msg = ("rollback config to mounted backup (created at %s)"):format(backup_handler["determine-active-backup-birthtime"](backup_handler))
    notify_once_21(msg, vim.log.levels.WARN)
    _3fconfig_code = read_file(mounted_backup_path)
  else
    if (secure_nvim_env_3f and denied_3f(config_file_path)) then
      vim.secure.trust({action = "remove", path = config_file_path})
      notify_once_21(("Previously the attempt to load %s has been denied.\nHowever, nvim-thyme asks you again to proceed just in case you accidentally denied your own config file."):format(config_filename))
    else
    end
    _3fconfig_code = vim.secure.read(config_file_path)
  end
  local compiler_options = {["error-pinpoint"] = {"|>>", "<<|"}, filename = config_file_path}
  local _
  cache["evaluating?"] = true
  _ = nil
  local ok_3f, _3fresult = nil, nil
  if _3fconfig_code then
    local function _30_()
      return fennel.eval(_3fconfig_code, compiler_options)
    end
    ok_3f, _3fresult = xpcall(_30_, fennel.traceback)
  else
    notify_once_21("Failed to read config, fallback to the default options", vim.log.levels.WARN)
    ok_3f, _3fresult = default_opts
  end
  local _0
  cache["evaluating?"] = false
  _0 = nil
  if ok_3f then
    local _3fconfig = _3fresult
    if (_3fconfig_code and backup_handler["should-update-backup?"](backup_handler, _3fconfig_code)) then
      backup_handler["write-backup!"](backup_handler, config_file_path)
      backup_handler["cleanup-old-backups!"](backup_handler)
    else
    end
    return (_3fconfig or {})
  else
    local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
    local error_msg = _3fresult
    local msg = ("failed to evaluating %s with the following error:\n%s"):format(config_filename, error_msg)
    notify_once_21(msg, vim.log.levels.ERROR)
    if file_readable_3f(backup_path) then
      local msg0 = ("temporarily restore config from backup created at %s\nHINT: You can reduce the annoying errors by `:ThymeRollbackMount` in new nvim sessions.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(backup_handler["determine-active-backup-birthtime"](backup_handler))
      notify_once_21(msg0, vim.log.levels.WARN)
      return fennel.dofile(backup_path, compiler_options)
    else
      notify_once_21("No backup found, fallback to the default options", vim.log.levels.WARN)
      return default_opts
    end
  end
end
cache["main-config"] = {}
local function get_config()
  if next(cache["main-config"]) then
    return cache["main-config"]
  else
    local user_config = read_config_with_backup_21(config_path)
    cache["main-config"] = vim.tbl_deep_extend("force", default_opts, user_config)
    return cache["main-config"]
  end
end
local function config_file_3f(path)
  return (config_filename == vim.fs.basename(path))
end
local function _36_()
  local config = vim.deepcopy(get_config())
  config["compiler-options"].source = nil
  config["compiler-options"]["module-name"] = nil
  config["compiler-options"].filename = nil
  if config.command["compiler-options"] then
    config.command["compiler-options"].source = nil
    config.command["compiler-options"]["module-name"] = nil
    config.command["compiler-options"].filename = nil
  else
  end
  return config
end
local function _38_(_self, k)
  if (k == "?error-msg") then
    if cache["evaluating?"] then
      return ("recursion detected in evaluating " .. config_filename)
    else
      return nil
    end
  else
    local _ = k
    local config = get_config()
    return (config[k] or error(("unexpected option detected: " .. k)))
  end
end
local _41_
if not debug_3f then
  local function _42_()
    return error("thyme.config is readonly")
  end
  _41_ = _42_
else
  _41_ = nil
end
return setmetatable({["config-file?"] = config_file_3f, ["get-config"] = _36_}, {__index = _38_, __newindex = _41_})
