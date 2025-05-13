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
                  RollbackCommander["switch-active-backup!"](kind, modname, _3fbackup_path)
                  return vim.cmd("ThymeCacheClear")
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
        return _16_(RollbackCommander["list-backups"](kind, modname))
      else
        local __44_ = _14_
        return ...
      end
    end
    return _13_(RollbackCommander["cmdargs->kind-modname"](args))
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _12_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _28_(_27_)
    local args = _27_["args"]
    local _29_, _30_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _29_) and (nil ~= _30_)) then
      local kind = _29_
      local modname = _30_
      return RollbackCommander["mount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _28_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _33_(_32_)
    local args = _32_["args"]
    local _34_, _35_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _34_) and (nil ~= _35_)) then
      local kind = _34_
      local modname = _35_
      return RollbackCommander["unmount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _33_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _37_()
    local _38_, _39_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_38_ == false) and (nil ~= _39_)) then
      local msg = _39_
      local tgt_40_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_40_)[msg](tgt_40_, vim.log.levels.WARN))
    else
      local _ = _38_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _37_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
