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
    local root = RollbackManager["get-root"]()
    local prefix = Path.join(root, args)
    local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
    local candidates = vim.fn.glob(glob_pattern, false, true)
    local _13_ = #candidates
    if (_13_ == 0) then
      return error(("Abort. No backup is found for " .. args))
    elseif (_13_ == 1) then
      return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. args), vim.log.levels.WARN)
    else
      local _ = _13_
      local function _14_(_241, _242)
        return (_242 < _241)
      end
      table.sort(candidates, _14_)
      local function _15_(path)
        local basename = vim.fs.basename(path)
        if RollbackManager["active-backup?"](path) then
          return (basename .. " (current)")
        else
          return basename
        end
      end
      local function _17_(_3fbackup_path)
        if _3fbackup_path then
          RollbackManager["switch-active-backup!"](_3fbackup_path)
          return vim.cmd("ThymeCacheClear")
        else
          return CommandMessenger["notify!"](CommandMessenger, "Abort selecting rollback target")
        end
      end
      return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(args), format_item = _15_}, _17_)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _12_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _21_(_20_)
    local args = _20_["args"]
    local _22_, _23_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _22_) and (nil ~= _23_)) then
      local kind = _22_
      local modname = _23_
      return RollbackCommander["mount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _21_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _26_(_25_)
    local args = _25_["args"]
    local _27_, _28_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _27_) and (nil ~= _28_)) then
      local kind = _27_
      local modname = _28_
      return RollbackCommander["unmount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _26_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _30_()
    local _31_, _32_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_31_ == false) and (nil ~= _32_)) then
      local msg = _32_
      local tgt_33_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_33_)[msg](tgt_33_, vim.log.levels.WARN))
    else
      local _ = _31_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _30_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
