local Path = require("thyme.utils.path")
local Messenger = require("thyme.utils.messenger")
local CommandMessenger = Messenger.new("command/rollback")
local RollbackManager = require("thyme.rollback.manager")
local M = {}
local RollbackCommander = {}
RollbackCommander["cmdargs->kind-modname"] = function(cmdargs)
  return cmdargs:match("([^/]+)/?([^/]*)")
end
RollbackCommander.attach = function(kind)
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/user/commands/rollback.fnl:19")
  local ext_tmp = ".tmp"
  return RollbackManager.new(kind, ext_tmp)
end
RollbackCommander["get-root"] = function(kind, modname)
  local tgt_1_ = RollbackCommander.attach(kind)
  local tgt_2_ = (tgt_1_)["backup-handler-of"](tgt_1_, modname)
  return (tgt_2_)["determine-backup-dir"](tgt_2_)
end
RollbackCommander["list-backup-kind-paths"] = function()
  return vim.fn.glob(Path.join(RollbackCommander["get-root"](), "*"), false, true)
end
RollbackCommander["list-backup-kinds"] = function()
  local tbl_21_ = {}
  local i_22_ = 0
  for _, path in ipairs(RollbackCommander["list-backup-kind-paths"]) do
    local val_23_ = vim.fs.basename(path)
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  return tbl_21_
end
RollbackCommander["list-backup-paths"] = function()
  return vim.fn.glob(Path.join(RollbackCommander["get-root"](), "*", "*"), false, true)
end
RollbackCommander["list-backup-identifiers"] = function()
  return string.match(RollbackCommander["list-backup-paths"](), "[^/\\]+/[^/\\]+$")
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
    local args = _12_["args"]
    local function _14_(...)
      local _15_, _16_ = ...
      if ((nil ~= _15_) and (nil ~= _16_)) then
        local kind = _15_
        local modname = _16_
        local function _17_(...)
          local _18_ = ...
          if (nil ~= _18_) then
            local candidates = _18_
            local _19_ = #candidates
            if (_19_ == 0) then
              return error(("Abort. No backup is found for " .. args))
            elseif (_19_ == 1) then
              return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. args), vim.log.levels.WARN)
            else
              local _ = _19_
              local function _20_(_241, _242)
                return (_242 < _241)
              end
              table.sort(candidates, _20_)
              local function _21_(path)
                local basename = vim.fs.basename(path)
                if RollbackManager["active-backup?"](path) then
                  return (basename .. " (current)")
                else
                  return basename
                end
              end
              local function _23_(_3fbackup_path)
                if _3fbackup_path then
                  return RollbackCommander["switch-active-backup!"](kind, modname, _3fbackup_path)
                else
                  return CommandMessenger["notify!"](CommandMessenger, "Abort selecting rollback target")
                end
              end
              return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(args), format_item = _21_}, _23_)
            end
          else
            local __44_ = _18_
            return ...
          end
        end
        local tgt_27_ = RollbackCommander.attach(kind)
        local tgt_28_ = (tgt_27_)["backup-handler-of"](tgt_27_, modname)
        return _17_((tgt_28_)["list-backup-files"](tgt_28_))
      else
        local __44_ = _15_
        return ...
      end
    end
    return _14_(RollbackCommander["cmdargs->kind-modname"](args))
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _13_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _31_(_30_)
    local args = _30_["args"]
    local _32_, _33_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _32_) and (nil ~= _33_)) then
      local kind = _32_
      local modname = _33_
      return RollbackCommander["mount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _31_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _36_(_35_)
    local args = _35_["args"]
    local _37_, _38_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _37_) and (nil ~= _38_)) then
      local kind = _37_
      local modname = _38_
      return RollbackCommander["unmount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _36_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _40_()
    local _41_, _42_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_41_ == false) and (nil ~= _42_)) then
      local msg = _42_
      local tgt_43_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_43_)[msg](tgt_43_, vim.log.levels.WARN))
    else
      local _ = _41_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _40_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
