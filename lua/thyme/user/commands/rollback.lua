local Path = require("thyme.utils.path")
local RollbackManager = require("thyme.rollback")
local M = {}
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
    local input = _12_["args"]
    local root = RollbackManager["get-root"]()
    local dir = Path.join(root, input)
    if RollbackManager["mount-backup!"](dir) then
      return vim.notify(("successfully mounted " .. dir), vim.log.levels.INFO)
    else
      return vim.notify(("failed to mount " .. dir), vim.log.levels.WARN)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _13_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _16_(_15_)
    local input = _15_["args"]
    local root = RollbackManager["get-root"]()
    local dir = Path.join(root, input)
    local _17_, _18_ = pcall(RollbackManager["unmount-backup!"], dir)
    if ((_17_ == false) and (nil ~= _18_)) then
      local msg = _18_
      return vim.notify(("failed to mount %s:\n%s"):format(dir, msg), vim.log.levels.WARN)
    else
      local _ = _17_
      return vim.notify(("successfully unmounted " .. dir), vim.log.levels.INFO)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _16_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _20_()
    local _21_, _22_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_21_ == false) and (nil ~= _22_)) then
      local msg = _22_
      return vim.notify(("failed to mount backups:\n%s"):format(msg), vim.log.levels.WARN)
    else
      local _ = _21_
      return vim.notify("successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _20_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
