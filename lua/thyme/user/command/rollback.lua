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
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/user/command/rollback.fnl:19")
  local ext_tmp = ".tmp"
  return RollbackManager.new(kind, ext_tmp)
end
RollbackCommander["get-root"] = function(kind, modname)
  local tgt_1_ = RollbackCommander.attach(kind)
  local tgt_2_ = (tgt_1_)["backup-handler-of"](tgt_1_, modname)
  return (tgt_2_)["determine-backup-dir"](tgt_2_)
end
RollbackCommander["list-backups"] = function(kind, modname)
  local dir = RollbackCommander["get-root"](kind, modname)
  local glob_pattern = Path.join(dir, "*.{lua,fnl}")
  local candidates = vim.fn.glob(glob_pattern, false, true)
  return candidates
end
RollbackCommander["switch-active-backup!"] = function(kind, modname, path)
  local tgt_3_ = RollbackCommander.attach(kind)
  local tgt_4_ = (tgt_3_)["backup-handler-of"](tgt_3_, modname)
  return (tgt_4_)["switch-active-backup!"](tgt_4_, path)
end
RollbackCommander["mount-backup!"] = function(kind, modname)
  local tgt_5_ = RollbackCommander.attach(kind)
  local tgt_6_ = (tgt_5_)["backup-handler-of"](tgt_5_, modname)
  return (tgt_6_)["mount-backup!"](tgt_6_)
end
RollbackCommander["unmount-backup!"] = function(kind, modname)
  local tgt_7_ = RollbackCommander.attach(kind)
  local tgt_8_ = (tgt_7_)["backup-handler-of"](tgt_7_, modname)
  return (tgt_8_)["unmount-backup!"](tgt_8_)
end
M["setup!"] = function()
  do
    local complete_dirs
    local function _9_(arg_lead, _cmdline, _cursorpos)
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
    complete_dirs = _9_
    local function _12_(_11_)
      local args = _11_["args"]
      local function _13_(...)
        local _14_, _15_ = ...
        if ((nil ~= _14_) and (nil ~= _15_)) then
          local kind = _14_
          local modname = _15_
          local function _16_(...)
            local _17_ = ...
            if (nil ~= _17_) then
              local candidates = _17_
              local _18_ = #candidates
              if (_18_ == 0) then
                return error(("Abort. No backup is found for " .. args))
              elseif (_18_ == 1) then
                return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. args), vim.log.levels.WARN)
              else
                local _ = _18_
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
              local __44_ = _17_
              return ...
            end
          end
          local tgt_26_ = RollbackCommander.attach(kind)
          local tgt_27_ = (tgt_26_)["backup-handler-of"](tgt_26_, modname)
          return _16_((tgt_27_)["list-backup-files"](tgt_27_))
        else
          local __44_ = _14_
          return ...
        end
      end
      return _13_(RollbackCommander["cmdargs->kind-modname"](args))
    end
    vim.api.nvim_create_user_command("ThymeRollbackSwitch", _12_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
    local function _30_(_29_)
      local args = _29_["args"]
      local _31_, _32_ = RollbackCommander["cmdargs->kind-modname"](args)
      if ((nil ~= _31_) and (nil ~= _32_)) then
        local kind = _31_
        local modname = _32_
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
    local tbl_21_ = {}
    local i_22_ = 0
    for _, path in ipairs(paths) do
      local val_23_ = path:sub(prefix_length, (-2 - #mounted_filename))
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    return tbl_21_
  end
  complete_mounted = _34_
  local function _37_(_36_)
    local args = _36_["args"]
    local _38_, _39_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _38_) and (nil ~= _39_)) then
      local kind = _38_
      local modname = _39_
      return RollbackCommander["unmount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _37_, {nargs = "?", complete = complete_mounted, desc = "[thyme] Unmount mounted backup"})
  local function _41_()
    local _42_, _43_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_42_ == false) and (nil ~= _43_)) then
      local msg = _43_
      local tgt_44_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_44_)[msg](tgt_44_, vim.log.levels.WARN))
    else
      local _ = _42_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _41_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
