local fennel = require("fennel")
local tts = require("thyme.wrapper.treesitter")
local _local_1_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_1_["apply-parinfer"]
local _local_2_ = require("thyme.const")
local lua_cache_prefix = _local_2_["lua-cache-prefix"]
local _local_3_ = require("thyme.util.fs")
local file_readable_3f = _local_3_["file-readable?"]
local Messenger = require("thyme.util.class.messenger")
local CommandMessenger = Messenger.new("command/fennel")
local Config = require("thyme.config")
local DependencyLogger = require("thyme.dependency.logger")
local fennel_wrapper = require("thyme.wrapper.fennel")
local fnl_file_compile = require("thyme.user.command.fennel.fnl-file-compile")
local M = {}
local function make_new_cmd(new_fnl_code, _4_)
  local trailing_parens = _4_["trailing-parens"]
  local trimmed_new_fnl_code = new_fnl_code:gsub("%s*[%]}%)]*$", "")
  local last_cmd = vim.fn.histget(":", -1)
  local _5_, _6_ = last_cmd:find(trimmed_new_fnl_code, 1, true)
  if ((nil ~= _5_) and (nil ~= _6_)) then
    local idx_start = _5_
    local idx_end = _6_
    local prefix = last_cmd:sub(1, (idx_start - 1))
    local suffix = new_fnl_code:gsub("%s*$", ""):sub((idx_end - idx_start - -2))
    local trimmed_suffix
    if (trailing_parens == "omit") then
      trimmed_suffix = suffix:gsub("^[%]}%)]*", "")
    elseif (trailing_parens == "keep") then
      trimmed_suffix = suffix
    else
      local _3fval = trailing_parens
      trimmed_suffix = error(("expected one of `omit` or `keep`; got unknown value for trailing-parens: " .. vim.inspect(_3fval)))
    end
    local new_cmd = (prefix .. trimmed_new_fnl_code .. trimmed_suffix)
    return new_cmd
  else
    return nil
  end
end
local function edit_cmd_history_21(new_fnl_code, _9_)
  local method = _9_["method"]
  local opts = _9_
  local methods
  local function _10_(new_cmd)
    assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
    return assert((1 == vim.fn.histdel(":", -2)), "failed to remove the replaced fnl code")
  end
  local function _11_(new_cmd)
    return assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
  end
  local function _12_()
    --[[ "Do nothing" ]]
    return nil
  end
  methods = {overwrite = _10_, append = _11_, ignore = _12_}
  local _13_ = methods[method]
  if (nil ~= _13_) then
    local apply_method = _13_
    local new_cmd = make_new_cmd(new_fnl_code, opts)
    return apply_method(new_cmd)
  else
    local _ = _13_
    return error(("expected one of `overwrite`, `append`, or `ignore`; got unknown method " .. method))
  end
end
local function wrap_fennel_wrapper_for_command(callback, _15_)
  local lang = _15_["lang"]
  local discard_last_3f = _15_["discard-last?"]
  local compiler_options = _15_["compiler-options"]
  local cmd_history_opts = _15_["cmd-history-opts"]
  local function _17_(_16_)
    local args = _16_["args"]
    local smods = _16_["smods"]
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args:gsub("\r", "\n"), {["cmd-history-opts"] = cmd_history_opts})
    if verbose_3f then
      tts.print(";;; Source")
      tts.print(new_fnl_code)
      tts.print(";;; Result")
    else
    end
    local results = {callback(new_fnl_code, compiler_options)}
    do
      local _19_ = #results
      if (_19_ == 0) then
        tts.print("nil", {lang = lang})
      elseif (nil ~= _19_) then
        local last_idx = _19_
        for i, _3ftext in ipairs(results) do
          if (discard_last_3f and (last_idx <= i)) then break end
          local text
          if (lang == "lua") then
            text = _3ftext
          else
            text = fennel.view(_3ftext, compiler_options)
          end
          tts.print(text, {lang = lang})
        end
      else
      end
    end
    local function _22_()
      local _23_, _24_ = pcall(vim.api.nvim_parse_cmd, vim.fn.histget(":"), {})
      if ((_23_ == true) and (nil ~= _24_)) then
        local cmdline = _24_
        if cmdline.cmd:find("^Fnl") then
          return edit_cmd_history_21(new_fnl_code, cmd_history_opts)
        else
          return nil
        end
      else
        return nil
      end
    end
    return vim.schedule(_22_)
  end
  return _17_
end
local function open_buf_21(buf_7cpath, _27_)
  local split = _27_["split"]
  local tab = _27_["tab"]
  local mods = _27_
  local split_3f = ((-1 ~= tab) or ("" ~= split))
  local cmd
  do
    local _28_ = type(buf_7cpath)
    if (_28_ == "number") then
      if split_3f then
        cmd = "sbuffer"
      else
        cmd = "buffer"
      end
    elseif (_28_ == "string") then
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
  local function _35_(_33_)
    local _arg_34_ = _33_["fargs"]
    local _3fpath = _arg_34_[1]
    local line1 = _33_["line1"]
    local line2 = _33_["line2"]
    local a = _33_
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
  vim.api.nvim_create_user_command("FnlBuf", _35_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _39_(_37_)
    local _arg_38_ = _37_["fargs"]
    local _3fpath = _arg_38_[1]
    local line1 = _37_["line1"]
    local line2 = _37_["line2"]
    local a = _37_
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
  vim.api.nvim_create_user_command("FnlFile", _39_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  vim.api.nvim_create_user_command("FnlCompile", wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "+", complete = "lua", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  do
    local cb
    local function _41_(_40_)
      local path = _40_["args"]
      local line1 = _40_["line1"]
      local line2 = _40_["line2"]
      local a = _40_
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
    cb = _41_
    local cmd_opts = {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"}
    vim.api.nvim_create_user_command("FnlBufCompile", cb, cmd_opts)
    vim.api.nvim_create_user_command("FnlCompileBuf", cb, cmd_opts)
  end
  local function _45_(_43_)
    local _arg_44_ = _43_["fargs"]
    local _3fpath = _arg_44_[1]
    local mods = _43_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _46_ = input_path:sub(-4)
      if (_46_ == ".fnl") then
        local _47_ = DependencyLogger["fnl-path->lua-path"](DependencyLogger, input_path)
        if (nil ~= _47_) then
          local lua_path = _47_
          output_path = lua_path
        else
          local _ = _47_
          local _48_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _48_) then
            local lua_path = _48_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_46_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _46_
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
  return vim.api.nvim_create_user_command("FnlAlternate", _45_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return M
