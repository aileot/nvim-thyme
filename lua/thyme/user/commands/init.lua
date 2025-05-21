local Path = require("thyme.util.path")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.util.fs")
local directory_3f = _local_2_["directory?"]
local Messenger = require("thyme.util.class.messenger")
local UninstallCommandMessenger = Messenger.new("command/uninstall")
local cache_commands = require("thyme.user.commands.cache")
local rollback_commands = require("thyme.user.commands.rollback")
local fennel_wrapper_commands = require("thyme.user.commands.fennel")
local function assert_is_file_of_thyme(path)
  local sep = (path:match("/") or "\\")
  assert((((sep .. "thyme") == path:sub(-6)) or path:find((sep .. "thyme" .. sep), 1, true)), (path .. " does not belong to thyme"))
  return path
end
local function define_commands_21(_3fopts)
  local function _3_()
    return vim.cmd(("edit " .. config_path))
  end
  vim.api.nvim_create_user_command("ThymeConfigOpen", _3_, {desc = ("[thyme] open the main config file " .. config_filename)})
  local function _4_()
    local _5_ = vim.fn.confirm("Delete all the thyme's cache, state, and data files? It will NOT modify your config files.", "&No\n&yes", 1, "Warning")
    if (_5_ == 2) then
      local files = {lua_cache_prefix, Path.join(vim.fn.stdpath("cache"), "thyme"), Path.join(vim.fn.stdpath("state"), "thyme"), Path.join(vim.fn.stdpath("data"), "thyme")}
      do
        local _6_ = vim.secure.trust({action = "remove", path = config_path})
        if (_6_ == true) then
          UninstallCommandMessenger["notify!"](UninstallCommandMessenger, "successfully untrust .nvim-thyme.fnl")
        else
        end
      end
      for _, path in ipairs(files) do
        assert_is_file_of_thyme(path)
        if directory_3f(path) then
          local _8_ = vim.fn.delete(path, "rf")
          if (_8_ == 0) then
            UninstallCommandMessenger["notify!"](UninstallCommandMessenger, ("successfully deleted " .. path))
          else
            local _0 = _8_
            error(("failed to delete " .. path))
          end
        else
        end
      end
      return UninstallCommandMessenger["notify!"](UninstallCommandMessenger, "successfully uninstalled")
    else
      local _ = _5_
      return UninstallCommandMessenger["notify!"](UninstallCommandMessenger, "aborted")
    end
  end
  vim.api.nvim_create_user_command("ThymeUninstall", _4_, {desc = "[thyme] delete all the thyme's cache, state, and data files"})
  cache_commands["setup!"]()
  rollback_commands["setup!"]()
  return fennel_wrapper_commands["setup!"](_3fopts)
end
return {["define-commands!"] = define_commands_21}
