local Path = require("thyme.util.path")
local Messenger = require("thyme.util.class.messenger")
local CommandMessenger = Messenger.new("command/rollback")
local RollbackManager = require("thyme.rollback.manager")
local M = {}
local RollbackCommander = {}
RollbackCommander["cmdargs->kind-modname"] = function(cmdargs)
  return cmdargs:match("([^/]+)/?([^/]*)")
end
RollbackCommander.attach = function(kind)
  if (nil == kind) then
    _G.error("Missing argument kind on fnl/thyme/user/command/rollback.fnl:19", 2)
  else
  end
  local ext_tmp = ".tmp"
  return RollbackManager.new(kind, ext_tmp)
end
RollbackCommander["get-root"] = function(kind, modname)
  local tgt_2_ = RollbackCommander.attach(kind)
  local tgt_3_ = (tgt_2_)["backup-handler-of"](tgt_2_, modname)
  return (tgt_3_)["determine-backup-dir"](tgt_3_)
end
RollbackCommander["list-backups"] = function(kind, modname)
  local dir = RollbackCommander["get-root"](kind, modname)
  local glob_pattern = Path.join(dir, "*.{lua,fnl}")
  local candidates = vim.fn.glob(glob_pattern, false, true)
  return candidates
end
RollbackCommander["switch-active-backup!"] = function(kind, modname, path)
  local tgt_4_ = RollbackCommander.attach(kind)
  local tgt_5_ = (tgt_4_)["backup-handler-of"](tgt_4_, modname)
  return (tgt_5_)["switch-active-backup!"](tgt_5_, path)
end
RollbackCommander["mount-backup!"] = function(kind, modname)
  local tgt_6_ = RollbackCommander.attach(kind)
  local tgt_7_ = (tgt_6_)["backup-handler-of"](tgt_6_, modname)
  return (tgt_7_)["mount-backup!"](tgt_7_)
end
RollbackCommander["unmount-backup!"] = function(kind, modname)
  local tgt_8_ = RollbackCommander.attach(kind)
  local tgt_9_ = (tgt_8_)["backup-handler-of"](tgt_8_, modname)
  return (tgt_9_)["unmount-backup!"](tgt_9_)
end
M["setup!"] = function()
  do
    local complete_dirs
    local function _10_(arg_lead, _cmdline, _cursorpos)
      local root = RollbackManager["get-root"]()
      local prefix_length = (2 + #root)
      local glob_pattern = Path.join(root, (arg_lead .. "**/"))
      local paths = vim.fn.glob(glob_pattern, false, true)
      local tbl_26_ = {}
      local i_27_ = 0
      for _, path in ipairs(paths) do
        local val_28_ = path:sub(prefix_length, -2)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      return tbl_26_
    end
    complete_dirs = _10_
    local function _13_(_12_)
      local args = _12_.args
      local function _14_(...)
        local case_15_, case_16_ = ...
        if ((nil ~= case_15_) and (nil ~= case_16_)) then
          local kind = case_15_
          local modname = case_16_
          local function _17_(...)
            if (nil ~= ...) then
              local candidates = ...
              local case_18_ = #candidates
              if (case_18_ == 0) then
                return error(("Abort. No backup is found for " .. args))
              elseif (case_18_ == 1) then
                return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. args), vim.log.levels.WARN)
              else
                local _ = case_18_
                local function _19_(_241, _242)
                  return (_242 < _241)
                end
                table.sort(candidates, _19_)
                local function _20_(path)
                  local basename = vim.fs.basename(path)
                  if RollbackManager["active-backup?"](path) then
                    return (basename .. " (current)")
                  else
                    return basename
                  end
                end
                local function _22_(_3fbackup_path)
                  if _3fbackup_path then
                    return RollbackCommander["switch-active-backup!"](kind, modname, _3fbackup_path)
                  else
                    return CommandMessenger["notify!"](CommandMessenger, "Abort selecting rollback target")
                  end
                end
                return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(args), format_item = _20_}, _22_)
              end
            else
              local __43_ = ...
              return ...
            end
          end
          local tgt_26_ = RollbackCommander.attach(kind)
          local tgt_27_ = (tgt_26_)["backup-handler-of"](tgt_26_, modname)
          return _17_((tgt_27_)["list-backup-files"](tgt_27_))
        else
          local __43_ = case_15_
          return ...
        end
      end
      return _14_(RollbackCommander["cmdargs->kind-modname"](args))
    end
    vim.api.nvim_create_user_command("ThymeRollbackSwitch", _13_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
    local function _30_(_29_)
      local args = _29_.args
      local case_31_, case_32_ = RollbackCommander["cmdargs->kind-modname"](args)
      if ((nil ~= case_31_) and (nil ~= case_32_)) then
        local kind = case_31_
        local modname = case_32_
        return RollbackCommander["mount-backup!"](kind, modname)
      else
        return nil
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackMount", _30_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  end
  local complete_mounted
  local function _34_(arg_lead, _cmdline, _cursorpos)
    local root = RollbackManager["get-root"]()
    local prefix_length = (2 + #root)
    local mounted_filename = ".mounted"
    local glob_patternn = Path.join(root, (arg_lead .. "**/" .. mounted_filename))
    local paths = vim.fn.glob(glob_patternn, false, true)
    local tbl_26_ = {}
    local i_27_ = 0
    for _, path in ipairs(paths) do
      local val_28_ = path:sub(prefix_length, (-2 - #mounted_filename))
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
  complete_mounted = _34_
  local function _37_(_36_)
    local args = _36_.args
    local case_38_, case_39_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= case_38_) and (nil ~= case_39_)) then
      local kind = case_38_
      local modname = case_39_
      return RollbackCommander["unmount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _37_, {nargs = "?", complete = complete_mounted, desc = "[thyme] Unmount mounted backup"})
  local function _41_()
    local case_42_, case_43_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((case_42_ == false) and (nil ~= case_43_)) then
      local msg = case_43_
      local tgt_44_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_44_)[msg](tgt_44_, vim.log.levels.WARN))
    else
      local _ = case_42_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _41_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
