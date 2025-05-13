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
RollbackCommander["mount-backup!"] = function(kind, modname)
  local tgt_1_ = RollbackCommander.attach(kind)
  local tgt_2_ = (tgt_1_)["backup-handler-of"](tgt_1_, modname)
  return (tgt_2_)["mount-backup!"](tgt_2_)
end
RollbackCommander["unmount-backup!"] = function(kind, modname)
  local tgt_3_ = RollbackCommander.attach(kind)
  local tgt_4_ = (tgt_3_)["backup-handler-of"](tgt_3_, modname)
  return (tgt_4_)["unmount-backup!"](tgt_4_)
end
M["setup!"] = function()
  local complete_dirs
  local function _5_(arg_lead, _cmdline, _cursorpos)
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
  complete_dirs = _5_
  local function _8_(_7_)
    local input = _7_["args"]
    local root = RollbackManager["get-root"]()
    local prefix = Path.join(root, input)
    local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
    local candidates = vim.fn.glob(glob_pattern, false, true)
    local _9_ = #candidates
    if (_9_ == 0) then
      return error(("Abort. No backup is found for " .. input))
    elseif (_9_ == 1) then
      return CommandMessenger["notify!"](CommandMessenger, ("Abort. Only one backup is found for " .. input), vim.log.levels.WARN)
    else
      local _ = _9_
      local function _10_(_241, _242)
        return (_242 < _241)
      end
      table.sort(candidates, _10_)
      local function _11_(path)
        local basename = vim.fs.basename(path)
        if RollbackManager["active-backup?"](path) then
          return (basename .. " (current)")
        else
          return basename
        end
      end
      local function _13_(_3fbackup_path)
        if _3fbackup_path then
          RollbackManager["switch-active-backup!"](_3fbackup_path)
          return vim.cmd("ThymeCacheClear")
        else
          return CommandMessenger["notify!"](CommandMessenger, "Abort selecting rollback target")
        end
      end
      return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _11_}, _13_)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _8_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _17_(_16_)
    local args = _16_["args"]
    local _18_, _19_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _18_) and (nil ~= _19_)) then
      local kind = _18_
      local modname = _19_
      return RollbackCommander["mount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _17_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _22_(_21_)
    local args = _21_["args"]
    local _23_, _24_ = RollbackCommander["cmdargs->kind-modname"](args)
    if ((nil ~= _23_) and (nil ~= _24_)) then
      local kind = _23_
      local modname = _24_
      return RollbackCommander["unmount-backup!"](kind, modname)
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _22_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _26_()
    local _27_, _28_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_27_ == false) and (nil ~= _28_)) then
      local msg = _28_
      local tgt_29_ = "format"
      return CommandMessenger["notify!"](CommandMessenger, "Failed to mount backups:\n%s", (tgt_29_)[msg](tgt_29_, vim.log.levels.WARN))
    else
      local _ = _27_
      return CommandMessenger["notify!"](CommandMessenger, "Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _26_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
