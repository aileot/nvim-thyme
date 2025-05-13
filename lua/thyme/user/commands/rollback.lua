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
RollbackCommander["switch-active-backup!"] = function(kind, modname, path)
  local tgt_1_ = RollbackCommander.attach(kind)
  local tgt_2_ = (tgt_1_)["backup-handler-of"](tgt_1_, modname)
  return (tgt_2_)["switch-active-backup!"](tgt_2_, path)
end
RollbackCommander["mount-backup!"] = function(kind, modname)
  local tgt_3_ = RollbackCommander.attach(kind)
  local tgt_4_ = (tgt_3_)["backup-handler-of"](tgt_3_, modname)
  return (tgt_4_)["mount-backup!"](tgt_4_)
end
RollbackCommander["unmount-backup!"] = function(kind, modname)
  local tgt_5_ = RollbackCommander.attach(kind)
  local tgt_6_ = (tgt_5_)["backup-handler-of"](tgt_5_, modname)
  return (tgt_6_)["unmount-backup!"](tgt_6_)
end
M["setup!"] = function()
  local complete_dirs
  local function _7_(arg_lead, _cmdline, _cursorpos)
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
  complete_dirs = _7_
  local function _10_(_9_)
    local input = _9_["args"]
    local root = RollbackManager["get-root"]()
    local prefix = Path.join(root, input)
    local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
    local candidates = vim.fn.glob(glob_pattern, false, true)
    local _11_ = #candidates
    if (_11_ == 0) then
      return error(("Abort. No backup is found for " .. input))
    elseif (_11_ == 1) then
      return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. input), vim.log.levels.WARN)
    else
      local _ = _11_
      local function _12_(_241, _242)
        return (_242 < _241)
      end
      table.sort(candidates, _12_)
      local function _13_(path)
        local basename = vim.fs.basename(path)
        if RollbackManager["active-backup?"](path) then
          return (basename .. " (current)")
        else
          return basename
        end
      end
      local function _15_(_3fbackup_path)
        if _3fbackup_path then
          RollbackManager["switch-active-backup!"](_3fbackup_path)
          return vim.cmd("ThymeCacheClear")
        else
          return CommandMessenger["notify!"](CommandMessenger, "Abort selecting rollback target")
        end
      end
      return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _13_}, _15_)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _10_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _19_(_18_)
    local args = _18_["args"]
    local _20_, _21_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _20_) and (nil ~= _21_)) then
      local kind = _20_
      local modname = _21_
      return RollbackCommander["mount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _19_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _24_(_23_)
    local args = _23_["args"]
    local _25_, _26_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _25_) and (nil ~= _26_)) then
      local kind = _25_
      local modname = _26_
      return RollbackCommander["unmount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _24_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _28_()
    local _29_, _30_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_29_ == false) and (nil ~= _30_)) then
      local msg = _30_
      local tgt_31_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_31_)[msg](tgt_31_, vim.log.levels.WARN))
    else
      local _ = _29_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _28_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
