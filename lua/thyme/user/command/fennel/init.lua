local _local_1_ = require("thyme.const")
local config_filename = _local_1_["config-filename"]
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local under_tmpdir_3f = _local_2_["under-tmpdir?"]
local Messenger = require("thyme.util.class.messenger")
local CommandMessenger = Messenger.new("command/fennel")
local Config = require("thyme.lazy-config")
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
local function resolve_missing_modules(callback, old_fnl_code, compiler_options)
  _G.assert((nil ~= compiler_options), "Missing argument compiler-options on fnl/thyme/user/command/fennel/init.fnl:46")
  _G.assert((nil ~= old_fnl_code), "Missing argument old-fnl-code on fnl/thyme/user/command/fennel/init.fnl:46")
  _G.assert((nil ~= callback), "Missing argument callback on fnl/thyme/user/command/fennel/init.fnl:46")
  local new_fnl_code = old_fnl_code
  local continue_3f = true
  local results = nil
  while continue_3f do
    local _14_
    local function _15_()
      return callback(new_fnl_code, compiler_options)
    end
    _14_ = {pcall(_15_)}
    if (_14_[1] == true) then
      local rest = {select(2, (table.unpack or _G.unpack)(_14_))}
      continue_3f = false
      results = rest
    elseif ((_14_[1] == false) and (nil ~= _14_[2])) then
      local msg = _14_[2]
      local _16_ = string.match(msg, "unknown identifier: ([^\n%s]+)")
      if (nil ~= _16_) then
        local missing_sym = _16_
        local new_line = ("(local %s (require %q))\n"):format(missing_sym, missing_sym)
        new_fnl_code = (new_line .. new_fnl_code)
      else
      end
    else
    end
  end
  return unpack(results)
end
M["setup!"] = function()
  local compiler_options = (Config.command["compiler-options"] or Config["compiler-options"])
  local cmd_history_opts = Config.command["cmd-history"]
  fnl_file_compile["create-commands!"]()
  local function _19_(a)
    local implicit_resolve_3f = Config.command["implicit-resolve"]
    local cb
    if implicit_resolve_3f then
      local function _20_(...)
        return resolve_missing_modules(fennel_wrapper.eval, ...)
      end
      cb = _20_
    else
      cb = fennel_wrapper.eval
    end
    local callback = mk_fennel_wrapper_command_callback(cb, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    if not (0 == a.count) then
      local buf = vim.api.nvim_get_current_buf()
      if should_include_buf_3f(buf) then
        local buf_lines = table.concat(vim.api.nvim_buf_get_lines(buf, (a.line1 - 1), a.line2, true), "\n")
        local fnl_args = (buf_lines .. "\n" .. a.args)
        a.args = fnl_args
      else
      end
    else
    end
    return callback(a)
  end
  vim.api.nvim_create_user_command("Fnl", _19_, {range = Config.command.Fnl["default-range"], nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  local function _24_(a)
    local fnl_code = parse_cmd_buf_args(a)
    local cmd_history_opts0 = {method = "ignore"}
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlBuf", _24_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _25_(a)
    local fnl_code = parse_cmd_file_args(a)
    local cmd_history_opts0 = {method = "ignore"}
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlFile", _25_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _26_(a)
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper["compile-string"], {lang = "lua", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    local buf = vim.api.nvim_get_current_buf()
    if ((0 ~= a.count) and should_include_buf_3f(buf)) then
      local fnl_code = table.concat(vim.api.nvim_buf_get_lines(buf, (a.line1 - 1), a.line2, true), "\n")
      a.args = (fnl_code .. "\n" .. a.args)
    else
    end
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlCompile", _26_, {range = Config.command.FnlCompile["default-range"], nargs = "*", complete = "lua", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  do
    local cb
    local function _28_(a)
      local fnl_code = parse_cmd_buf_args(a)
      local cmd_history_opts0 = {method = "ignore"}
      local callback = mk_fennel_wrapper_command_callback(fennel_wrapper["compile-string"], {lang = "lua", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
      a.args = fnl_code
      return callback(a)
    end
    cb = _28_
    local cmd_opts = {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of given buffer, or current buffer as fennel expression"}
    vim.api.nvim_create_user_command("FnlBufCompile", cb, cmd_opts)
    vim.api.nvim_create_user_command("FnlCompileBuf", cb, cmd_opts)
  end
  local function _31_(_29_)
    local _arg_30_ = _29_["fargs"]
    local _3fpath = _arg_30_[1]
    local mods = _29_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _32_ = input_path:sub(-4)
      if (_32_ == ".fnl") then
        local _33_ = DependencyLogger["fnl-path->lua-path"](DependencyLogger, input_path)
        if (nil ~= _33_) then
          local lua_path = _33_
          output_path = lua_path
        else
          local _ = _33_
          local _34_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _34_) then
            local lua_path = _34_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_32_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _32_
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
  return vim.api.nvim_create_user_command("FnlAlternate", _31_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return M
