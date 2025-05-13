local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.fs")
local file_readable_3f = _local_1_["file-readable?"]
local _local_2_ = require("thyme.utils.pool")
local hide_file_21 = _local_2_["hide-file!"]
local Messenger = require("thyme.utils.messenger")
local CommandMessenger = Messenger.new("command/rollback")
local _local_3_ = require("thyme.compiler.cache")
local determine_lua_path = _local_3_["determine-lua-path"]
local RollbackManager = require("thyme.rollback.manager")
local M = {}
local RollbackCommandBackend = {}
RollbackCommandBackend.attach = function(kind)
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/user/commands/rollback.fnl:15")
  local ext_tmp = ".tmp"
  return RollbackManager.new(kind, ext_tmp)
end
RollbackCommandBackend["mount-backup!"] = function(kind, modname)
  local ext_tmp = ".tmp"
  local backup_handler
  local tgt_4_ = RollbackCommandBackend.attach(kind, ext_tmp)
  backup_handler = (tgt_4_)["backup-handler-of"](tgt_4_, modname)
  local ok_3f = backup_handler["mount-backup!"](backup_handler)
  if (ok_3f and (kind == "module")) then
    local _5_ = determine_lua_path(modname)
    if (nil ~= _5_) then
      local lua_path = _5_
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
  local backup_handler
  local tgt_9_ = RollbackCommandBackend.attach(kind, ext_tmp)
  backup_handler = (tgt_9_)["backup-handler-of"](tgt_9_, modname)
  return backup_handler["unmount-backup!"](backup_handler)
end
RollbackCommandBackend["cmdargs->kind-modname"] = function(cmdargs)
  return cmdargs:match("([^/]+)/?([^/]*)")
end
M["setup!"] = function()
  local complete_dirs
  local function _10_(arg_lead, _cmdline, _cursorpos)
    local root = RollbackManager["get-root"]()
    local prefix_length = (2 + #root)
    local glob_pattern = Path.join(root, (arg_lead .. "**/"))
    local paths = vim.fn.glob(glob_pattern, false, true)
    local tbl_21_ = {}
    local i_22_ = 0
    for _, path in ipairs(paths) do
      local val_23_ = path:sub(prefix_length, -2)
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    return tbl_21_
  end
  complete_dirs = _10_
  local function _13_(_12_)
    local input = _12_["args"]
    local root = RollbackManager["get-root"]()
    local prefix = Path.join(root, input)
    local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
    local candidates = vim.fn.glob(glob_pattern, false, true)
    local _14_ = #candidates
    if (_14_ == 0) then
      return error(("Abort. No backup is found for " .. input))
    elseif (_14_ == 1) then
      return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. input), vim.log.levels.WARN)
    else
      local _ = _14_
      local function _15_(_241, _242)
        return (_242 < _241)
      end
      table.sort(candidates, _15_)
      local function _16_(path)
        local basename = vim.fs.basename(path)
        if RollbackManager["active-backup?"](path) then
          return (basename .. " (current)")
        else
          return basename
        end
      end
      local function _18_(_3fbackup_path)
        if _3fbackup_path then
          RollbackManager["switch-active-backup!"](_3fbackup_path)
          return vim.cmd("ThymeCacheClear")
        else
          return CommandMessenger["notify!"](CommandMessenger, "Abort selecting rollback target")
        end
      end
      return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _16_}, _18_)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _13_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _22_(_21_)
    local args = _21_["args"]
    local _23_, _24_ = RollbackCommandBackend["cmdargs->kind-modname"](args)
    if ((nil ~= _23_) and (nil ~= _24_)) then
      local kind = _23_
      local modname = _24_
      if RollbackCommandBackend["mount-backup!"](kind, modname) then
        return CommandMessenger["notify!"](CommandMessenger, ("Successfully mounted " .. args), vim.log.levels.INFO)
      else
        return CommandMessenger["notify!"](CommandMessenger, ("Failed to mount " .. args), vim.log.levels.WARN)
      end
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _22_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _28_(_27_)
    local args = _27_["args"]
    local _29_, _30_ = RollbackCommandBackend["cmdargs->kind-modname"](args)
    if ((nil ~= _29_) and (nil ~= _30_)) then
      local kind = _29_
      local modname = _30_
      local _31_, _32_ = pcall(RollbackCommandBackend["unmount-backup!"], kind, modname)
      if ((_31_ == false) and (nil ~= _32_)) then
        local msg = _32_
        local tgt_33_ = "format"
        return CommandMessenger["notify!"](CommandMessenger, "Failed to mount %s:\n%s", (tgt_33_)[args](tgt_33_, msg, vim.log.levels.WARN))
      else
        local _ = _31_
        return CommandMessenger["notify!"](CommandMessenger, ("Successfully unmounted " .. args), vim.log.levels.INFO)
      end
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _28_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _36_()
    local _37_, _38_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_37_ == false) and (nil ~= _38_)) then
      local msg = _38_
      local tgt_39_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_39_)[msg](tgt_39_, vim.log.levels.WARN))
    else
      local _ = _37_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _36_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
