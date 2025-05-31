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
local wrap_fennel_wrapper_for_command = _local_3_["wrap-fennel-wrapper-for-command"]
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
  vim.api.nvim_create_user_command("Fnl", wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "+", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  local function _12_(_10_)
    local _arg_11_ = _10_["fargs"]
    local _3fpath = _arg_11_[1]
    local line1 = _10_["line1"]
    local line2 = _10_["line2"]
    local a = _10_
    local fnl_code
    do
      local bufnr
      if _3fpath then
        bufnr = vim.fn.bufnr(_3fpath)
      else
        bufnr = 0
      end
      fnl_code = table.concat(vim.api.nvim_buf_get_lines(bufnr, (line1 - 1), line2, true), "\n")
    end
    local cmd_history_opts0 = {method = "ignore"}
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlBuf", _12_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _16_(_14_)
    local _arg_15_ = _14_["fargs"]
    local _3fpath = _arg_15_[1]
    local line1 = _14_["line1"]
    local line2 = _14_["line2"]
    local a = _14_
    local fnl_code
    do
      local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
      fnl_code = table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
    end
    local cmd_history_opts0 = {method = "ignore"}
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command("FnlFile", _16_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  vim.api.nvim_create_user_command("FnlCompile", wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "+", complete = "lua", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  do
    local cb
    local function _18_(_17_)
      local path = _17_["args"]
      local line1 = _17_["line1"]
      local line2 = _17_["line2"]
      local a = _17_
      local bufnr
      if path:find("^%s*$") then
        bufnr = 0
      else
        bufnr = vim.fn.bufnr(path)
      end
      local fnl_code = table.concat(vim.api.nvim_buf_get_lines(bufnr, (line1 - 1), line2, true), "\n")
      local cmd_history_opts0 = {method = "ignore"}
      local callback = wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts0})
      a.args = fnl_code
      return callback(a)
    end
    cb = _18_
    local cmd_opts = {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"}
    vim.api.nvim_create_user_command("FnlBufCompile", cb, cmd_opts)
    vim.api.nvim_create_user_command("FnlCompileBuf", cb, cmd_opts)
  end
  local function _22_(_20_)
    local _arg_21_ = _20_["fargs"]
    local _3fpath = _arg_21_[1]
    local mods = _20_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _23_ = input_path:sub(-4)
      if (_23_ == ".fnl") then
        local _24_ = DependencyLogger["fnl-path->lua-path"](DependencyLogger, input_path)
        if (nil ~= _24_) then
          local lua_path = _24_
          output_path = lua_path
        else
          local _ = _24_
          local _25_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _25_) then
            local lua_path = _25_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_23_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _23_
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
  return vim.api.nvim_create_user_command("FnlAlternate", _22_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return M
