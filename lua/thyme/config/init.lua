local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_fnl_file = _local_2_["assert-is-fnl-file"]
local read_file = _local_2_["read-file"]
do
  local Fallback = require("thyme.config.fallback")
  if Fallback["should-fallback?"]() then
    Fallback["prompt-fallback-config!"]()
  else
  end
end
local default_opts = require("thyme.config.defaults")
local _local_4_ = require("thyme.util.trust")
local denied_3f = _local_4_["denied?"]
local RollbackManager = require("thyme.rollback.manager")
local ConfigRollbackManager = RollbackManager.new("config", ".fnl")
local nvim_appname = vim.env.NVIM_APPNAME
local secure_nvim_env_3f = ((nil == nvim_appname) or ("" == nvim_appname))
local cache = {}
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
    local function _7_()
      return fennel.eval(_3fconfig_code, compiler_options)
    end
    ok_3f, _3fresult = xpcall(_7_, fennel.traceback)
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
local function _13_()
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
local function _15_(_self, k)
  if (k == "?error-msg") then
    if cache["evaluating?"] then
      return ("recursion detected in evaluating " .. config_filename)
    else
      return nil
    end
  else
    local _ = k
    local config = get_config()
    local _17_ = default_opts[k]
    if (_17_ == nil) then
      return error(("unexpected option detected: %s\ndefault-values:\n%s"):format(k, vim.inspect(default_opts)))
    else
      local _0 = _17_
      return config[k]
    end
  end
end
local _20_
if not debug_3f then
  local function _21_(_, key)
    return error(("thyme.config is readonly; accessing " .. key))
  end
  _20_ = _21_
else
  _20_ = nil
end
return setmetatable({["config-file?"] = config_file_3f, ["get-config"] = _13_}, {__index = _15_, __newindex = _20_})
