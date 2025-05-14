local fennel = require("fennel")
local tts = require("thyme.wrapper.treesitter")
local _local_1_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_1_["apply-parinfer"]
local _local_2_ = require("thyme.const")
local lua_cache_prefix = _local_2_["lua-cache-prefix"]
local _local_3_ = require("thyme.utils.fs")
local file_readable_3f = _local_3_["file-readable?"]
local read_file = _local_3_["read-file"]
local write_lua_file_21 = _local_3_["write-lua-file!"]
local Messenger = require("thyme.utils.messenger")
local CommandMessenger = Messenger.new("command/fennel")
local _local_4_ = require("thyme.config")
local config_file_3f = _local_4_["config-file?"]
local Config = _local_4_
local DependencyLogger = require("thyme.dependency.logger")
local fennel_wrapper = require("thyme.wrapper.fennel")
local M = {}
local function make_new_cmd(new_fnl_code, _5_)
  local trailing_parens = _5_["trailing-parens"]
  local trimmed_new_fnl_code = new_fnl_code:gsub("%s*[%]}%)]*$", "")
  local last_cmd = vim.fn.histget(":", -1)
  local _6_, _7_ = last_cmd:find(trimmed_new_fnl_code, 1, true)
  if ((nil ~= _6_) and (nil ~= _7_)) then
    local idx_start = _6_
    local idx_end = _7_
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
local function edit_cmd_history_21(new_fnl_code, _10_)
  local method = _10_["method"]
  local opts = _10_
  local methods
  local function _11_(new_cmd)
    assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
    return assert((1 == vim.fn.histdel(":", -2)), "failed to remove the replaced fnl code")
  end
  local function _12_(new_cmd)
    return assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
  end
  local function _13_()
    --[[ "Do nothing" ]]
    return nil
  end
  methods = {overwrite = _11_, append = _12_, ignore = _13_}
  local _14_ = methods[method]
  if (nil ~= _14_) then
    local apply_method = _14_
    local new_cmd = make_new_cmd(new_fnl_code, opts)
    return apply_method(new_cmd)
  else
    local _ = _14_
    return error(("expected one of `overwrite`, `append`, or `ignore`; got unknown method " .. method))
  end
end
local function wrap_fennel_wrapper_for_command(callback, _16_)
  local lang = _16_["lang"]
  local discard_last_3f = _16_["discard-last?"]
  local compiler_options = _16_["compiler-options"]
  local cmd_history_opts = _16_["cmd-history-opts"]
  local function _18_(_17_)
    local args = _17_["args"]
    local smods = _17_["smods"]
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args, {["cmd-history-opts"] = cmd_history_opts})
    if verbose_3f then
      tts.print(";;; Source")
      tts.print(new_fnl_code)
      tts.print(";;; Result")
    else
    end
    local results = {callback(new_fnl_code, compiler_options)}
    do
      local _20_ = #results
      if (_20_ == 0) then
        tts.print("nil", {lang = lang})
      elseif (nil ~= _20_) then
        local last_idx = _20_
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
    local function _23_()
      return edit_cmd_history_21(new_fnl_code, cmd_history_opts)
    end
    return vim.schedule(_23_)
  end
  return _18_
end
local function open_buffer_21(buf_7cpath, _24_)
  local split = _24_["split"]
  local tab = _24_["tab"]
  local mods = _24_
  local split_3f = ((-1 ~= tab) or ("" ~= split))
  local cmd
  do
    local _25_ = type(buf_7cpath)
    if (_25_ == "number") then
      if split_3f then
        cmd = "sbuffer"
      else
        cmd = "buffer"
      end
    elseif (_25_ == "string") then
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
  local fnl_cmd_prefix = opts["fnl-cmd-prefix"]
  local compiler_options = opts["compiler-options"]
  local cmd_history_opts = opts["cmd-history"]
  if not ("" == fnl_cmd_prefix) then
    vim.api.nvim_create_user_command(fnl_cmd_prefix, wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  else
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Eval"), wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileString"), wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  local function _33_(_31_)
    local _arg_32_ = _31_["fargs"]
    local _3fpath = _arg_32_[1]
    local line1 = _31_["line1"]
    local line2 = _31_["line2"]
    local a = _31_
    local fnl_code
    do
      local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
      fnl_code = table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
    end
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalFile"), _33_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _36_(_34_)
    local _arg_35_ = _34_["fargs"]
    local _3fpath = _arg_35_[1]
    local line1 = _34_["line1"]
    local line2 = _34_["line2"]
    local a = _34_
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
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalBuffer"), _36_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _40_(_38_)
    local _arg_39_ = _38_["fargs"]
    local _3fpath = _arg_39_[1]
    local line1 = _38_["line1"]
    local line2 = _38_["line2"]
    local a = _38_
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
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileBuffer"), _40_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"})
  local function _43_(_42_)
    local glob_paths = _42_["fargs"]
    local force_compile_3f = _42_["bang"]
    local fnl_paths
    if (0 == #glob_paths) then
      fnl_paths = {vim.api.nvim_buf_get_name(0)}
    else
      local _44_
      do
        local tbl_21_ = {}
        local i_22_ = 0
        for _, path in ipairs(glob_paths) do
          local val_23_ = vim.split(vim.fn.glob(path), "\n")
          if (nil ~= val_23_) then
            i_22_ = (i_22_ + 1)
            tbl_21_[i_22_] = val_23_
          else
          end
        end
        _44_ = tbl_21_
      end
      fnl_paths = vim.fn.flatten(_44_, 1)
    end
    local path_pairs
    do
      local tbl_16_ = {}
      for _, path in ipairs(fnl_paths) do
        local k_17_, v_18_ = nil, nil
        do
          local full_path = vim.fn.fnamemodify(path, ":p")
          k_17_, v_18_ = full_path, DependencyLogger["fnl-path->lua-path"](DependencyLogger, full_path)
        end
        if ((k_17_ ~= nil) and (v_18_ ~= nil)) then
          tbl_16_[k_17_] = v_18_
        else
        end
      end
      path_pairs = tbl_16_
    end
    local existing_lua_files = {}
    local or_48_ = force_compile_3f
    if not or_48_ then
      local _49_
      do
        local tbl_21_ = {}
        local i_22_ = 0
        for _, lua_file in pairs(path_pairs) do
          local val_23_
          if file_readable_3f(lua_file) then
            val_23_ = table.insert(existing_lua_files, lua_file)
          else
            val_23_ = nil
          end
          if (nil ~= val_23_) then
            i_22_ = (i_22_ + 1)
            tbl_21_[i_22_] = val_23_
          else
          end
        end
        _49_ = tbl_21_
      end
      local and_52_ = _49_
      if and_52_ then
        if (0 < #existing_lua_files) then
          local _53_ = vim.fn.confirm(("The following files have already existed:\n    " .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
          if (_53_ == 2) then
            and_52_ = true
          else
            local _ = _53_
            CommandMessenger["notify!"](CommandMessenger, "Abort")
            and_52_ = false
          end
        else
          and_52_ = nil
        end
      end
      or_48_ = and_52_
    end
    if or_48_ then
      local fennel_options = Config["compiler-options"]
      for fnl_path, lua_path in pairs(path_pairs) do
        assert(not config_file_3f(fnl_path), "Abort. Attempted to compile config file")
        local lua_lines = fennel_wrapper["compile-file"](fnl_path, fennel_options)
        if (lua_lines == read_file(lua_path)) then
          CommandMessenger["notify!"](CommandMessenger, ("Abort. Nothing has changed in " .. fnl_path))
        else
          local msg = (fnl_path .. " is compiled into " .. lua_path)
          write_lua_file_21(lua_path, lua_lines)
          CommandMessenger["notify!"](CommandMessenger, msg)
        end
      end
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileFile"), _43_, {nargs = "*", bang = true, complete = "file", desc = "Compile given fnl files, or current fnl buffer"})
  local function _63_(_61_)
    local _arg_62_ = _61_["fargs"]
    local _3fpath = _arg_62_[1]
    local mods = _61_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _64_ = input_path:sub(-4)
      if (_64_ == ".fnl") then
        local _65_ = DependencyLogger["fnl-path->lua-path"](DependencyLogger, input_path)
        if (nil ~= _65_) then
          local lua_path = _65_
          output_path = lua_path
        else
          local _ = _65_
          local _66_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _66_) then
            local lua_path = _66_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_64_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _64_
        output_path = error("expected a fnl or lua file, got", input_path)
      end
    end
    if file_readable_3f(output_path) then
      return open_buffer_21(output_path, mods)
    else
      if not mods.emsg_silent then
        return CommandMessenger["notify!"](CommandMessenger, ("failed to find the alternate file of " .. input_path), vim.log.levels.WARN)
      else
        return nil
      end
    end
  end
  return vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Alternate"), _63_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return M
