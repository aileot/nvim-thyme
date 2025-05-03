local _local_1_ = require("thyme.const")
local debug_3f = _local_1_["debug?"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.utils.fs")
local file_readable_3f = _local_2_["file-readable?"]
local assert_is_fnl_file = _local_2_["assert-is-fnl-file"]
local read_file = _local_2_["read-file"]
local write_fnl_file_21 = _local_2_["write-fnl-file!"]
local RollbackManager = require("thyme.utils.rollback")
local ConfigRollbackManager = RollbackManager.new("config", ".fnl")
local nvim_appname = vim.env.NVIM_APPNAME
local secure_nvim_env_3f = ((nil == nvim_appname) or ("" == nvim_appname))
local default_opts = {["max-rollbacks"] = 10, preproc = nil, ["compiler-options"] = {}, ["fnl-dir"] = "fnl", ["macro-path"] = table.concat({"./fnl/?.fnlm", "./fnl/?/init.fnlm", "./fnl/?.fnl", "./fnl/?/init-macros.fnl", "./fnl/?/init.fnl"}, ";")}
local cache = {}
local function _3_(self, k)
  if (k == "?error-msg") then
    return nil
  else
    local _4_ = rawget(default_opts, k)
    if (nil ~= _4_) then
      local val = _4_
      rawset(self, k, val)
      return val
    else
      local _ = _4_
      return error(("unexpected option detected: " .. vim.inspect(k)))
    end
  end
end
local _7_
if debug_3f then
  local function _8_(self, k, v)
    return rawset(self, k, v)
  end
  _7_ = _8_
else
  local function _9_(_, k)
    return error(("unexpected option detected: " .. vim.inspect(k)))
  end
  _7_ = _9_
end
cache["main-config"] = setmetatable({}, {__index = _3_, __newindex = _7_})
if not file_readable_3f(config_path) then
  local _11_ = vim.fn.confirm(("Missing \"%s\" at %s. Generate and open it?"):format(config_filename, vim.fn.stdpath("config")), "&No\n&yes", 1, "Warning")
  if (_11_ == 2) then
    local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
    local example_config_filename = (config_filename .. ".example")
    local _let_12_ = vim.fs.find(example_config_filename, {upward = true, type = "file", path = this_dir})
    local example_config_path = _let_12_[1]
    local recommended_config = read_file(example_config_path)
    write_fnl_file_21(config_path, recommended_config)
    vim.cmd.tabedit(config_path)
    local function _13_()
      if (config_path == vim.api.nvim_buf_get_name(0)) then
        local _14_ = vim.fn.confirm("Trust this file? Otherwise, it will ask your trust again on nvim restart", "&Yes\n&no", 1, "Question")
        if (_14_ == 2) then
          return error(("abort trusting " .. config_path))
        else
          local _ = _14_
          return vim.cmd.trust()
        end
      else
        return nil
      end
    end
    vim.defer_fn(_13_, 800)
  else
    local _ = _11_
    error("abort proceeding with nvim-thyme")
  end
else
end
local function read_config_with_backup_21(config_file_path)
  assert_is_fnl_file(config_file_path)
  local fennel = require("fennel")
  local config_code
  if secure_nvim_env_3f then
    config_code = read_file(config_file_path)
  else
    config_code = vim.secure.read(config_file_path)
  end
  local compiler_options = {["error-pinpoint"] = {"|>>", "<<|"}, filename = config_file_path}
  local backup_name = "default"
  local _
  cache["evaluating?"] = true
  _ = nil
  local ok_3f, _3fresult = pcall(fennel.eval, config_code, compiler_options)
  local _0
  cache["evaluating?"] = false
  _0 = nil
  if ok_3f then
    local _3fconfig = _3fresult
    if ConfigRollbackManager["should-update-backup?"](ConfigRollbackManager, backup_name, config_code) then
      ConfigRollbackManager["create-module-backup!"](ConfigRollbackManager, backup_name, config_file_path)
      ConfigRollbackManager["cleanup-old-backups!"](ConfigRollbackManager, backup_name)
    else
    end
    return (_3fconfig or {})
  else
    local backup_path = ConfigRollbackManager["module-name->active-backup-path"](ConfigRollbackManager, backup_name)
    local error_msg = _3fresult
    local msg = ("[thyme] failed to evaluating %s with the following error:\n%s"):format(config_filename, error_msg)
    vim.notify_once(msg, vim.log.levels.ERROR)
    if file_readable_3f(backup_path) then
      local msg0 = ("[thyme] temporarily restore config from backup created at %s"):format(ConfigRollbackManager["module-name->active-backup-birthtime"](ConfigRollbackManager, backup_name))
      vim.notify_once(msg0, vim.log.levels.WARN)
      return fennel.dofile(backup_path, compiler_options)
    else
      return {}
    end
  end
end
local function get_config()
  if cache["evaluating?"] then
    return {["?error-msg"] = ("recursion detected in evaluating " .. config_filename)}
  elseif next(cache["main-config"]) then
    return cache["main-config"]
  else
    local user_config = read_config_with_backup_21(config_path)
    for k, v in pairs(user_config) do
      rawset(cache["main-config"], k, v)
    end
    return cache["main-config"]
  end
end
local function config_file_3f(path)
  return (config_filename == vim.fs.basename(path))
end
return {["get-config"] = get_config, ["config-file?"] = config_file_3f}
