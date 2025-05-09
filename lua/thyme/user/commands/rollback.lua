local Path = require("thyme.utils.path")
local RollbackManager = require("thyme.rollback")
local M = {}
local RollbackCommandBackend = {}
RollbackCommandBackend.attach = function(kind)
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/user/commands/rollback.fnl:11")
  local ext_tmp = ".tmp"
  return RollbackManager.new(kind, ext_tmp)
end
RollbackCommandBackend["mount-backup!"] = function(kind, module_name)
  local ext_tmp = ".tmp"
  local backup_handler = RollbackCommandBackend.attach(kind, ext_tmp):backupHandlerOf(module_name)
  return backup_handler["mount-backup!"](backup_handler)
end
M["setup!"] = function()
  local complete_dirs
  local function _1_(arg_lead, _cmdline, _cursorpos)
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
  complete_dirs = _1_
  local function _4_(_3_)
    local input = _3_["args"]
    local root = RollbackManager["get-root"]()
    local prefix = Path.join(root, input)
    local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
    local candidates = vim.fn.glob(glob_pattern, false, true)
    local _5_ = #candidates
    if (_5_ == 0) then
      return vim.notify(("Abort. No backup is found for " .. input))
    elseif (_5_ == 1) then
      return vim.notify(("Abort. Only one backup is found for " .. input))
    else
      local _ = _5_
      local function _6_(_241, _242)
        return (_242 < _241)
      end
      table.sort(candidates, _6_)
      local function _7_(path)
        local basename = vim.fs.basename(path)
        if RollbackManager["active-backup?"](path) then
          return (basename .. " (current)")
        else
          return basename
        end
      end
      local function _9_(_3fbackup_path)
        if _3fbackup_path then
          RollbackManager["switch-active-backup!"](_3fbackup_path)
          return vim.cmd("ThymeCacheClear")
        else
          return vim.notify("Abort selecting rollback target")
        end
      end
      return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _7_}, _9_)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _4_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _13_(_12_)
    local args = _12_["args"]
    local _14_, _15_ = args:match("([^/]+)/?([^/]*)")
    if ((nil ~= _14_) and (nil ~= _15_)) then
      local kind = _14_
      local module_name = _15_
      if RollbackCommandBackend["mount-backup!"](kind, module_name) then
        return vim.notify(("Successfully mounted " .. args), vim.log.levels.INFO)
      else
        return vim.notify(("Failed to mount " .. args), vim.log.levels.WARN)
      end
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _13_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _19_(_18_)
    local input = _18_["args"]
    local root = RollbackManager["get-root"]()
    local dir = Path.join(root, input)
    local _20_, _21_ = pcall(RollbackManager["unmount-backup!"], dir)
    if ((_20_ == false) and (nil ~= _21_)) then
      local msg = _21_
      return vim.notify(("Failed to mount %s:\n%s"):format(dir, msg), vim.log.levels.WARN)
    else
      local _ = _20_
      return vim.notify(("Successfully unmounted " .. dir), vim.log.levels.INFO)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _19_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _23_()
    local _24_, _25_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_24_ == false) and (nil ~= _25_)) then
      local msg = _25_
      return vim.notify(("Failed to mount backups:\n%s"):format(msg), vim.log.levels.WARN)
    else
      local _ = _24_
      return vim.notify("Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _23_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
