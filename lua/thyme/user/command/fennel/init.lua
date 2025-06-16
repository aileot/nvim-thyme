local _local_1_ = require("thyme.const")
local config_filename = _local_1_["config-filename"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local under_tmpdir_3f = _local_2_["under-tmpdir?"]
local Messenger = require("thyme.util.class.messenger")
local CommandMessenger = Messenger.new("command/fennel")
local Config = require("thyme.config")
local DependencyLogger = require("thyme.dependency.logger")
local fennel_wrapper = require("thyme.wrapper.fennel")
local _local_3_ = require("thyme.user.command.fennel.fennel-wrapper")
local parse_cmd_buf_args = _local_3_["parse-cmd-buf-args"]
local parse_cmd_file_args = _local_3_["parse-cmd-file-args"]
local mk_fennel_wrapper_command_callback = _local_3_["mk-fennel-wrapper-command-callback"]
local fnl_file_compile = require("thyme.user.command.fennel.fnl-file-compile")
local M = {}
local function open_buf_21(buf_7cpath, _4_)
  local split = _4_["split"]
  local tab = _4_["tab"]
  local mods = _4_
  local split_3f = ((-1 ~= tab) or ("" ~= split))
  local cmd
  do
    local _5_ = type(buf_7cpath)
    if (_5_ == "number") then
      if split_3f then
        cmd = "sbuffer"
      else
        cmd = "buffer"
      end
    elseif (_5_ == "string") then
      if split_3f then
        cmd = "split"
      else
        cmd = "edit"
      end
    else
      cmd = nil
    end
  end
  return vim.cmd({cmd = cmd, args = {buf_7cpath}, mods = mods})
end
local function should_include_buf_3f(buf)
  local _10_
  do
    local t_9_ = vim.bo
    if (nil ~= t_9_) then
      t_9_ = t_9_[buf]
    else
    end
    if (nil ~= t_9_) then
      t_9_ = t_9_.filetype
    else
    end
    _10_ = t_9_
  end
  if ("fennel" == _10_) then
    local buf_name = vim.api.nvim_buf_get_name(buf)
    return (vim.fs.root(buf, config_filename) or not file_readable_3f(buf_name) or under_tmpdir_3f(buf_name))
  else
    return nil
  end
end
M["setup!"] = function()
  local compiler_options = (Config.command["compiler-options"] or Config["compiler-options"])
  local cmd_history_opts = Config.command["cmd-history"]
  fnl_file_compile["create-commands!"]()
  local function _14_(a)
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    local buf = vim.api.nvim_get_current_buf()
    if ((0 ~= a.count) and should_include_buf_3f(buf)) then
      local fnl_code = table.concat(vim.api.nvim_buf_get_lines(buf, (a.line1 - 1), a.line2, true), "\n")
      a.args = (fnl_code .. "\n" .. a.args)
    else
    end
    return callback(a)
  end
  vim.api.nvim_create_user_command("Fnl", _14_, {range = Config.command.Fnl["default-range"], nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  local function _16_(a)
    local fnl_code = parse_cmd_buf_args(a)
    local cmd_history_opts0 = {method = "ignore"}
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlBuf", _16_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _17_(a)
    local fnl_code = parse_cmd_file_args(a)
    local cmd_history_opts0 = {method = "ignore"}
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlFile", _17_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _18_(a)
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper["compile-string"], {lang = "lua", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    local buf = vim.api.nvim_get_current_buf()
    if ((0 ~= a.count) and should_include_buf_3f(buf)) then
      local fnl_code = table.concat(vim.api.nvim_buf_get_lines(buf, (a.line1 - 1), a.line2, true), "\n")
      a.args = (fnl_code .. "\n" .. a.args)
    else
    end
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlCompile", _18_, {range = Config.command.FnlCompile["default-range"], nargs = "*", complete = "lua", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  do
    local cb
    local function _20_(a)
      local fnl_code = parse_cmd_buf_args(a)
      local cmd_history_opts0 = {method = "ignore"}
      local callback = mk_fennel_wrapper_command_callback(fennel_wrapper["compile-string"], {lang = "lua", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
      a.args = fnl_code
      return callback(a)
    end
    cb = _20_
    local cmd_opts = {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of given buffer, or current buffer as fennel expression"}
    vim.api.nvim_create_user_command("FnlBufCompile", cb, cmd_opts)
    vim.api.nvim_create_user_command("FnlCompileBuf", cb, cmd_opts)
  end
  local function _23_(_21_)
    local _arg_22_ = _21_["fargs"]
    local _3fpath = _arg_22_[1]
    local mods = _21_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _24_ = input_path:sub(-4)
      if (_24_ == ".fnl") then
        local _25_ = DependencyLogger["fnl-path->lua-path"](DependencyLogger, input_path)
        if (nil ~= _25_) then
          local lua_path = _25_
          output_path = lua_path
        else
          local _ = _25_
          local _26_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _26_) then
            local lua_path = _26_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_24_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _24_
        output_path = error("expected a fnl or lua file, got", input_path)
      end
    end
    if file_readable_3f(output_path) then
      return open_buf_21(output_path, mods)
    else
      if not mods.emsg_silent then
        return CommandMessenger["notify!"](CommandMessenger, ("failed to find the alternate file of " .. input_path), vim.log.levels.WARN)
      else
        return nil
      end
    end
  end
  return vim.api.nvim_create_user_command("FnlAlternate", _23_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return M
