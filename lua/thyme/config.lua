local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_fnl_file = _local_2_["assert-is-fnl-file"]
local read_file = _local_2_["read-file"]
local write_fnl_file_21 = _local_2_["write-fnl-file!"]
local Messenger = require("thyme.utils.messenger")
local ConfigMessenger = Messenger.new("config")
local RollbackManager = require("thyme.rollback")
local ConfigRollbackManager = RollbackManager.new("config", ".fnl")
local nvim_appname = vim.env.NVIM_APPNAME
local secure_nvim_env_3f = ((nil == nvim_appname) or ("" == nvim_appname))
local default_opts = {["max-rollbacks"] = 10, preproc = nil, ["compiler-options"] = {}, ["fnl-dir"] = "fnl", ["macro-path"] = table.concat({"./fnl/?.fnlm", "./fnl/?/init.fnlm", "./fnl/?.fnl", "./fnl/?/init-macros.fnl", "./fnl/?/init.fnl"}, ";"), command = {["compiler-options"] = nil, ["fnl-cmd-prefix"] = "Fnl", ["cmd-history"] = {method = "overwrite", ["trailing-parens"] = "omit"}}, watch = {event = {"BufWritePost", "FileChangedShellPost"}, pattern = "*.{fnl,fnlm}", strategy = "recompile"}}
local cache = {}
if not file_readable_3f(config_path) then
  local _3_ = vim.fn.confirm(("Missing \"%s\" at %s. Generate and open it?"):format(config_filename, vim.fn.stdpath("config")), "&No\n&yes", 1, "Warning")
  if (_3_ == 2) then
    local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
    local example_config_filename = (config_filename .. ".example")
    local _let_4_ = vim.fs.find(example_config_filename, {upward = true, type = "file", path = this_dir})
    local example_config_path = _let_4_[1]
    local recommended_config = read_file(example_config_path)
    write_fnl_file_21(config_path, recommended_config)
    vim.cmd.tabedit(config_path)
    local function _5_()
      if (config_path == vim.api.nvim_buf_get_name(0)) then
        local _6_ = vim.fn.confirm("Trust this file? Otherwise, it will ask your trust again on nvim restart", "&Yes\n&no", 1, "Question")
        if (_6_ == 2) then
          return error(("abort trusting " .. config_path))
        else
          local _ = _6_
          return vim.cmd.trust()
        end
      else
        return nil
      end
    end
    vim.defer_fn(_5_, 800)
  else
    local _ = _3_
    error("abort proceeding with nvim-thyme")
  end
else
end
local function read_config_with_backup_21(config_file_path)
  assert_is_fnl_file(config_file_path)
  local fennel = require("fennel")
  local backup_name = "default"
  local backup_handler = ConfigRollbackManager:backupHandlerOf(backup_name)
  local mounted_backup_path = backup_handler["determine-mounted-backup-path"](backup_handler)
  local config_code
  if file_readable_3f(mounted_backup_path) then
    local msg = ("rollback config to mounted backup (created at %s)"):format(backup_handler["determine-active-backup-birthtime"](backup_handler))
    ConfigMessenger["notify-once!"](ConfigMessenger, msg, vim.log.levels.WARN)
    config_code = read_file(mounted_backup_path)
  elseif secure_nvim_env_3f then
    config_code = read_file(config_file_path)
  else
    config_code = vim.secure.read(config_file_path)
  end
  local compiler_options = {["error-pinpoint"] = {"|>>", "<<|"}, filename = config_file_path}
  local _
  cache["evaluating?"] = true
  _ = nil
  local ok_3f, _3fresult = pcall(fennel.eval, config_code, compiler_options)
  local _0
  cache["evaluating?"] = false
  _0 = nil
  if ok_3f then
    local _3fconfig = _3fresult
    if backup_handler["should-update-backup?"](backup_handler, config_code) then
      backup_handler["write-backup!"](backup_handler, config_file_path)
      backup_handler["cleanup-old-backups!"](backup_handler)
    else
    end
    return (_3fconfig or {})
  else
    local backup_path = backup_handler["determine-active-backup-path"](backup_handler)
    local error_msg = _3fresult
    local msg = ("failed to evaluating %s with the following error:\n%s"):format(config_filename, error_msg)
    ConfigMessenger["notify-once!"](ConfigMessenger, msg, vim.log.levels.ERROR)
    if file_readable_3f(backup_path) then
      local msg0 = ("temporarily restore config from backup created at %s\nHINT: You can reduce its annoying errors during repairing the module running `:ThymeRollbackMount` to keep the active backup in the next nvim session.\nTo stop the forced rollback after repair, please run `:ThymeRollbackUnmount` or `:ThymeRollbackUnmountAll`."):format(backup_handler["determine-active-backup-birthtime"](backup_handler))
      ConfigMessenger["notify-once!"](ConfigMessenger, msg0, vim.log.levels.WARN)
      return fennel.dofile(backup_path, compiler_options)
    else
      return {}
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
local function _16_()
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
local function _18_(_self, k)
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
local _21_
if not debug_3f then
  local function _22_()
    return error("thyme.config is readonly")
  end
  _21_ = _22_
else
  _21_ = nil
end
return setmetatable({["config-file?"] = config_file_3f, ["get-config"] = _16_}, {__index = _18_, __newindex = _21_})
