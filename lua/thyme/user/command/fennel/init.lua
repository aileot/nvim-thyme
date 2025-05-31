local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.util.fs")
local file_readable_3f = _local_2_["file-readable?"]
local Messenger = require("thyme.util.class.messenger")
local CommandMessenger = Messenger.new("command/fennel")
local Config = require("thyme.config")
local DependencyLogger = require("thyme.dependency.logger")
local fennel_wrapper = require("thyme.wrapper.fennel")
local _local_3_ = require("thyme.user.command.fennel.fennel-wrapper")
local parse_cmd_buf_args = _local_3_["parse-cmd-buf-args"]
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
M["setup!"] = function(_3fopts)
  local opts
  if _3fopts then
    opts = vim.tbl_deep_extend("force", Config.command, _3fopts)
  else
    opts = Config.command
  end
  local compiler_options = opts["compiler-options"]
  local cmd_history_opts = opts["cmd-history"]
  fnl_file_compile["create-commands!"]()
  vim.api.nvim_create_user_command("Fnl", mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "+", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  local function _10_(a)
    local fnl_code = parse_cmd_buf_args(a)
    local cmd_history_opts0 = {method = "ignore"}
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlBuf", _10_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _13_(_11_)
    local _arg_12_ = _11_["fargs"]
    local _3fpath = _arg_12_[1]
    local line1 = _11_["line1"]
    local line2 = _11_["line2"]
    local a = _11_
    local fnl_code
    do
      local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
      fnl_code = table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
    end
    local cmd_history_opts0 = {method = "ignore"}
    local callback = mk_fennel_wrapper_command_callback(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlFile", _13_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  vim.api.nvim_create_user_command("FnlCompile", mk_fennel_wrapper_command_callback(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "+", complete = "lua", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  do
    local cb
    local function _14_(a)
      local fnl_code = parse_cmd_buf_args(a)
      local cmd_history_opts0 = {method = "ignore"}
      local callback = mk_fennel_wrapper_command_callback(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
      a.args = fnl_code
      return callback(a)
    end
    cb = _14_
    local cmd_opts = {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"}
    vim.api.nvim_create_user_command("FnlBufCompile", cb, cmd_opts)
    vim.api.nvim_create_user_command("FnlCompileBuf", cb, cmd_opts)
  end
  local function _17_(_15_)
    local _arg_16_ = _15_["fargs"]
    local _3fpath = _arg_16_[1]
    local mods = _15_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _18_ = input_path:sub(-4)
      if (_18_ == ".fnl") then
        local _19_ = DependencyLogger["fnl-path->lua-path"](DependencyLogger, input_path)
        if (nil ~= _19_) then
          local lua_path = _19_
          output_path = lua_path
        else
          local _ = _19_
          local _20_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _20_) then
            local lua_path = _20_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_18_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _18_
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
  return vim.api.nvim_create_user_command("FnlAlternate", _17_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return M
