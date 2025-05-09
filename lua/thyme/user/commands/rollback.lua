local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.utils.pool")
local hide_file_21 = _local_1_["hide-file!"]
local _local_2_ = require("thyme.compiler.cache")
local determine_lua_path = _local_2_["determine-lua-path"]
local RollbackManager = require("thyme.rollback")
local M = {}
local RollbackCommandBackend = {}
RollbackCommandBackend.attach = function(kind)
  _G.assert((nil ~= kind), "Missing argument kind on fnl/thyme/user/commands/rollback.fnl:12")
  local ext_tmp = ".tmp"
  return RollbackManager.new(kind, ext_tmp)
end
RollbackCommandBackend["mount-backup!"] = function(kind, modname)
  local ext_tmp = ".tmp"
  local backup_handler = RollbackCommandBackend.attach(kind, ext_tmp):backupHandlerOf(modname)
  local ok_3f = backup_handler["mount-backup!"](backup_handler)
  if (ok_3f and (kind == "module")) then
    local _3_ = determine_lua_path(modname)
    if (nil ~= _3_) then
      local lua_path = _3_
      hide_file_21(lua_path)
    else
    end
  else
  end
  return ok_3f
end
RollbackCommandBackend["unmount-backup!"] = function(kind, modname)
  local ext_tmp = ".tmp"
  local backup_handler = RollbackCommandBackend.attach(kind, ext_tmp):backupHandlerOf(modname)
  return backup_handler["unmount-backup!"](backup_handler)
end
RollbackCommandBackend["cmdargs->kind-modname"] = function(cmdargs)
  return cmdargs:match("([^/]+)/?([^/]*)")
end
M["setup!"] = function()
  local complete_dirs
  local function _6_(arg_lead, _cmdline, _cursorpos)
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
  complete_dirs = _6_
  local function _9_(_8_)
    local input = _8_["args"]
    local root = RollbackManager["get-root"]()
    local prefix = Path.join(root, input)
    local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
    local candidates = vim.fn.glob(glob_pattern, false, true)
    local _10_ = #candidates
    if (_10_ == 0) then
      return vim.notify(("Abort. No backup is found for " .. input))
    elseif (_10_ == 1) then
      return vim.notify(("Abort. Only one backup is found for " .. input))
    else
      local _ = _10_
      local function _11_(_241, _242)
        return (_242 < _241)
      end
      table.sort(candidates, _11_)
      local function _12_(path)
        local basename = vim.fs.basename(path)
        if RollbackManager["active-backup?"](path) then
          return (basename .. " (current)")
        else
          return basename
        end
      end
      local function _14_(_3fbackup_path)
        if _3fbackup_path then
          RollbackManager["switch-active-backup!"](_3fbackup_path)
          return vim.cmd("ThymeCacheClear")
        else
          return vim.notify("Abort selecting rollback target")
        end
      end
      return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _12_}, _14_)
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackSwitch", _9_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
  local function _18_(_17_)
    local args = _17_["args"]
    local _19_, _20_ = RollbackCommandBackend["cmdargs->kind-modname"](args)
    if ((nil ~= _19_) and (nil ~= _20_)) then
      local kind = _19_
      local modname = _20_
      if RollbackCommandBackend["mount-backup!"](kind, modname) then
        return vim.notify(("Successfully mounted " .. args), vim.log.levels.INFO)
      else
        return vim.notify(("Failed to mount " .. args), vim.log.levels.WARN)
      end
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackMount", _18_, {nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
  local function _24_(_23_)
    local args = _23_["args"]
    local _25_, _26_ = RollbackCommandBackend["cmdargs->kind-modname"](args)
    if ((nil ~= _25_) and (nil ~= _26_)) then
      local kind = _25_
      local modname = _26_
      local _27_, _28_ = pcall(RollbackCommandBackend["unmount-backup!"], kind, modname)
      if ((_27_ == false) and (nil ~= _28_)) then
        local msg = _28_
        return vim.notify(("Failed to mount %s:\n%s"):format(args, msg), vim.log.levels.WARN)
      else
        local _ = _27_
        return vim.notify(("Successfully unmounted " .. args), vim.log.levels.INFO)
      end
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command("ThymeRollbackUnmount", _24_, {nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
  local function _31_()
    local _32_, _33_ = pcall(RollbackManager["unmount-backup-all!"])
    if ((_32_ == false) and (nil ~= _33_)) then
      local msg = _33_
      return vim.notify(("Failed to mount backups:\n%s"):format(msg), vim.log.levels.WARN)
    else
      local _ = _32_
      return vim.notify("Successfully unmounted all the backups", vim.log.levels.INFO)
    end
  end
  return vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _31_, {nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
end
return M
