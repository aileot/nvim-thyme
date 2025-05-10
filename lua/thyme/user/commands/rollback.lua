local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local _local_2_ = require("thyme.utils.pool")
local hide_file_21 = _local_2_["hide-file!"]
local Messenger = require("thyme.utils.messenger")
local CommandMessenger = Messenger.new("command/rollback")
local _local_3_ = require("thyme.compiler.cache")
local determine_lua_path = _local_3_["determine-lua-path"]
local RollbackManager = require("thyme.rollback")
local M = {}
local RollbackCommandBackend = {}
RollbackCommandBackend.attach = function(kind)
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/user/commands/rollback.fnl:15")
  local ext_tmp = ".tmp"
  return RollbackManager.new(kind, ext_tmp)
end
RollbackCommandBackend["mount-backup!"] = function(kind, modname)
  local ext_tmp = ".tmp"
  local backup_handler = RollbackCommandBackend.attach(kind, ext_tmp):backupHandlerOf(modname)
  local ok_3f = backup_handler["mount-backup!"](backup_handler)
  if (ok_3f and (kind == "module")) then
    local _4_ = determine_lua_path(modname)
    if (nil ~= _4_) then
      local lua_path = _4_
      if file_readable_3f(lua_path) then
        hide_file_21(lua_path)
      else
      end
    else
    end
  else
  end
  return ok_3f
end
RollbackCommandBackend["unmount-backup!"] = function(kind, modname)
  local ext_tmp = ".tmp"
  local backup_handler = RollbackCommandBackend.attach(kind, ext_tmp):backupHandlerOf(modname)
  return backup_handler["unmount-backup!"](backup_handler)
end
RollbackCommandBackend["cmdargs->kind-modname"] = function(cmdargs)
  return cmdargs:match("([^/]+)/?([^/]*)")
end
M["setup!"] = function()
  local complete_dirs
  local function _8_(arg_lead, _cmdline, _cursorpos)
    local root = RollbackManager["get-root"]()
    local prefix_length = (2 + #root)
    local glob_pattern = Path.join(root, (arg_lead .. "**/"))
    local paths = vim.fn.glob(glob_pattern, false, true)
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, path in ipairs(paths) do
      local val_23_auto = path:sub(prefix_length, -2)
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    return tbl_21_auto
  end
  complete_dirs = _8_
  local function _11_(_10_)
    local input = _10_["args"]
    local root = RollbackManager["get-root"]()
    local prefix = Path.join(root, input)
    local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
    local candidates = vim.fn.glob(glob_pattern, false, true)
    local _12_ = #candidates
    if (_12_ == 0) then
      return CommandMessenger["notify!"](CommandMessenger, ("Abort. No backup is found for " .. input))
    elseif (_12_ == 1) then
      return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. input))
    else
      local _ = _12_
      local function _13_(_241, _242)
        return (_242 < _241)
      end
      table.sort(candidates, _13_)
      local function _14_(path)
        local basename = vim.fs.basename(path)
        if RollbackManager["active-backup?"](path) then
          return (basename .. " (current)")
        else
          return basename
        end
      end
      local function _16_(_3fbackup_path)
        if _3fbackup_path then
          RollbackManager["switch-active-backup!"](_3fbackup_path)
          return vim.cmd("ThymeCacheClear")
        else
          return CommandMessenger["notify!"](CommandMessenger, "Abort selecting rollback target")
        end
      end
      return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _14_}, _16_)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _11_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _20_(_19_)
    local args = _19_["args"]
    local _21_, _22_ = RollbackCommandBackend["cmdargs->kind-modname"](args)
    if ((nil ~= _21_) and (nil ~= _22_)) then
      local kind = _21_
      local modname = _22_
      if RollbackCommandBackend["mount-backup!"](kind, modname) then
        return CommandMessenger["notify!"](CommandMessenger, ("Successfully mounted " .. args), vim.log.levels.INFO)
      else
        return CommandMessenger["notify!"](CommandMessenger, ("Failed to mount " .. args), vim.log.levels.WARN)
      end
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _20_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _26_(_25_)
    local args = _25_["args"]
    local _27_, _28_ = RollbackCommandBackend["cmdargs->kind-modname"](args)
    if ((nil ~= _27_) and (nil ~= _28_)) then
      local kind = _27_
      local modname = _28_
      local _29_, _30_ = pcall(RollbackCommandBackend["unmount-backup!"], kind, modname)
      if ((_29_ == false) and (nil ~= _30_)) then
        local msg = _30_
        local tgt_31_ = "format"
        return CommandMessenger["notify!"](CommandMessenger, "Failed to mount %s:\n%s", (tgt_31_)[args](tgt_31_, msg, vim.log.levels.WARN))
      else
        local _ = _29_
        return CommandMessenger["notify!"](CommandMessenger, ("Successfully unmounted " .. args), vim.log.levels.INFO)
      end
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _26_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _34_()
    local _35_, _36_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_35_ == false) and (nil ~= _36_)) then
      local msg = _36_
      local tgt_37_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_37_)[msg](tgt_37_, vim.log.levels.WARN))
    else
      local _ = _35_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _34_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
