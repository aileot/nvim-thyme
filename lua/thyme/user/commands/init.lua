local Path = require("thyme.utils.path")
local tts = require("thyme.wrapper.treesitter")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.config")
local config_file_3f = _local_2_["config-file?"]
local Config = _local_2_
local _local_3_ = require("thyme.utils.fs")
local file_readable_3f = _local_3_["file-readable?"]
local directory_3f = _local_3_["directory?"]
local read_file = _local_3_["read-file"]
local write_lua_file_21 = _local_3_["write-lua-file!"]
local fennel_wrapper = require("thyme.wrapper.fennel")
local _local_4_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_4_["apply-parinfer"]
local _local_5_ = require("thyme.module-map.logger")
local fnl_path__3elua_path = _local_5_["fnl-path->lua-path"]
local fennel = require("fennel")
local cache_commands = require("thyme.user.commands.cache")
local rollback_commands = require("thyme.user.commands.rollback")
local function open_buffer_21(buf_7cpath, _6_)
  local split = _6_["split"]
  local tab = _6_["tab"]
  local mods = _6_
  local split_3f = ((-1 ~= tab) or ("" ~= split))
  local cmd
  do
    local _7_ = type(buf_7cpath)
    if (_7_ == "number") then
      if split_3f then
        cmd = "sbuffer"
      else
        cmd = "buffer"
      end
    elseif (_7_ == "string") then
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
local function edit_cmd_history_21(new_fnl_code, opts)
  local make_new_cmd
  local function _11_(new_fnl_code0)
    local trimmed_new_fnl_code = new_fnl_code0:gsub("%s*[%]}%)]*$", "")
    local last_cmd = vim.fn.histget(":", -1)
    local _12_, _13_ = last_cmd:find(trimmed_new_fnl_code, 1, true)
    if ((nil ~= _12_) and (nil ~= _13_)) then
      local idx_start = _12_
      local idx_end = _13_
      local prefix = last_cmd:sub(1, (idx_start - 1))
      local suffix = new_fnl_code0:gsub("%s*$", ""):sub((idx_end - idx_start - -2))
      local trimmed_suffix
      do
        local _14_ = opts["trailing-parens"]
        if (_14_ == "omit") then
          trimmed_suffix = suffix:gsub("^[%]}%)]*", "")
        elseif (_14_ == "keep") then
          trimmed_suffix = suffix
        else
          local _3fval = _14_
          trimmed_suffix = error(("expected one of `omit` or `keep`; got unknown value for trailing-parens: " .. vim.inspect(_3fval)))
        end
      end
      local new_cmd = (prefix .. trimmed_new_fnl_code .. trimmed_suffix)
      return new_cmd
    else
      return nil
    end
  end
  make_new_cmd = _11_
  local methods
  local function _17_(new_cmd)
    assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
    return assert((1 == vim.fn.histdel(":", -2)), "failed to remove the replaced fnl code")
  end
  local function _18_(new_cmd)
    return assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
  end
  local function _19_()
    --[[ "Do nothing" ]]
    return nil
  end
  methods = {overwrite = _17_, append = _18_, ignore = _19_}
  local _20_ = methods[opts.method]
  if (nil ~= _20_) then
    local apply_method = _20_
    local new_cmd = make_new_cmd(new_fnl_code)
    return apply_method(new_cmd)
  else
    local _ = _20_
    return error(("expected one of `overwrite`, `append`, or `ignore`; got unknown method " .. opts.method))
  end
end
local function wrap_fennel_wrapper_for_command(callback, _22_)
  local lang = _22_["lang"]
  local discard_last_3f = _22_["discard-last?"]
  local compiler_options = _22_["compiler-options"]
  local cmd_history_opts = _22_["cmd-history-opts"]
  local function _24_(_23_)
    local args = _23_["args"]
    local smods = _23_["smods"]
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
      local _26_ = #results
      if (_26_ == 0) then
        tts.print("nil", {lang = lang})
      elseif (nil ~= _26_) then
        local last_idx = _26_
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
    local function _29_()
      return edit_cmd_history_21(new_fnl_code, cmd_history_opts)
    end
    return vim.schedule(_29_)
  end
  return _24_
end
local function assert_is_file_of_thyme(path)
  local sep = (path:match("/") or "\\")
  assert((((sep .. "thyme") == path:sub(-6)) or path:find((sep .. "thyme" .. sep), 1, true)), (path .. " does not belong to thyme"))
  return path
end
local function define_commands_21(_3fopts)
  local opts
  if _3fopts then
    opts = vim.tbl_deep_extend("force", Config.command, _3fopts)
  else
    opts = Config.command
  end
  local fnl_cmd_prefix = opts["fnl-cmd-prefix"]
  local compiler_options = opts["compiler-options"]
  local cmd_history_opts = opts["cmd-history"]
  local function _31_()
    return vim.cmd(("tab drop " .. config_path))
  end
  vim.api.nvim_create_user_command("ThymeConfigOpen", _31_, {desc = ("[thyme] open the main config file " .. config_filename)})
  local function _32_()
    local files = {lua_cache_prefix, Path.join(vim.fn.stdpath("cache"), "thyme"), Path.join(vim.fn.stdpath("state"), "thyme"), Path.join(vim.fn.stdpath("data"), "thyme")}
    for _, path in ipairs(files) do
      assert_is_file_of_thyme(path)
      if directory_3f(path) then
        local _33_ = vim.fn.delete(path, "rf")
        if (_33_ == 0) then
          vim.notify(("[thyme] successfully deleted " .. path))
        else
          local _0 = _33_
          error(("[thyme] failed to delete " .. path))
        end
      else
      end
    end
    return vim.notify("[thyme] successfully uninstalled")
  end
  vim.api.nvim_create_user_command("ThymeUninstall", _32_, {desc = "[thyme] delete all the thyme's cache, state, and data files"})
  cache_commands["setup!"]()
  rollback_commands["setup!"]()
  if not ("" == fnl_cmd_prefix) then
    vim.api.nvim_create_user_command(fnl_cmd_prefix, wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  else
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Eval"), wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileString"), wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", desc = "[thyme] display the compiled lua results of the following fennel expression"})
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
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalFile"), _39_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _42_(_40_)
    local _arg_41_ = _40_["fargs"]
    local _3fpath = _arg_41_[1]
    local line1 = _40_["line1"]
    local line2 = _40_["line2"]
    local a = _40_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalBuffer"), _42_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _46_(_44_)
    local _arg_45_ = _44_["fargs"]
    local _3fpath = _arg_45_[1]
    local line1 = _44_["line1"]
    local line2 = _44_["line2"]
    local a = _44_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileBuffer"), _46_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"})
  local function _49_(_48_)
    local glob_paths = _48_["fargs"]
    local force_compile_3f = _48_["bang"]
    local fnl_paths
    if (0 == #glob_paths) then
      fnl_paths = {vim.api.nvim_buf_get_name(0)}
    else
      local _50_
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for _, path in ipairs(glob_paths) do
          local val_23_auto = vim.split(vim.fn.glob(path), "\n")
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        _50_ = tbl_21_auto
      end
      fnl_paths = vim.fn.flatten(_50_, 1)
    end
    local path_pairs
    do
      local tbl_16_auto = {}
      for _, path in ipairs(fnl_paths) do
        local k_17_auto, v_18_auto = nil, nil
        do
          local full_path = vim.fn.fnamemodify(path, ":p")
          k_17_auto, v_18_auto = full_path, fnl_path__3elua_path(full_path)
        end
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      path_pairs = tbl_16_auto
    end
    local existing_lua_files = {}
    local or_54_ = force_compile_3f
    if not or_54_ then
      local _55_
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for _, lua_file in pairs(path_pairs) do
          local val_23_auto
          if file_readable_3f(lua_file) then
            val_23_auto = table.insert(existing_lua_files, lua_file)
          else
            val_23_auto = nil
          end
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        _55_ = tbl_21_auto
      end
      local and_58_ = _55_
      if and_58_ then
        if (0 < #existing_lua_files) then
          local _59_ = vim.fn.confirm(("The following files have already existed:\n" .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
          if (_59_ == 2) then
            and_58_ = true
          else
            local _ = _59_
            vim.notify("Abort")
            and_58_ = false
          end
        else
          and_58_ = nil
        end
      end
      or_54_ = and_58_
    end
    if or_54_ then
      local fennel_options = Config["compiler-options"]
      for fnl_path, lua_path in pairs(path_pairs) do
        assert(not config_file_3f(fnl_path), "Abort. Attempted to compile config file")
        local lua_lines = fennel_wrapper["compile-file"](fnl_path, fennel_options)
        if (lua_lines == read_file(lua_path)) then
          vim.notify(("Abort. Nothing has changed in " .. fnl_path))
        else
          local msg = (fnl_path .. " is compiled into " .. lua_path)
          write_lua_file_21(lua_path, lua_lines)
          vim.notify(msg)
        end
      end
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileFile"), _49_, {nargs = "*", bang = true, complete = "file", desc = "Compile given fnl files, or current fnl buffer"})
  local function _69_(_67_)
    local _arg_68_ = _67_["fargs"]
    local _3fpath = _arg_68_[1]
    local mods = _67_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _70_ = input_path:sub(-4)
      if (_70_ == ".fnl") then
        local _71_ = fnl_path__3elua_path(input_path)
        if (nil ~= _71_) then
          local lua_path = _71_
          output_path = lua_path
        else
          local _ = _71_
          local _72_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _72_) then
            local lua_path = _72_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_70_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _70_
        output_path = error("expected a fnl or lua file, got", input_path)
      end
    end
    if file_readable_3f(output_path) then
      return open_buffer_21(output_path, mods)
    else
      if not mods.emsg_silent then
        return vim.notify(("failed to find the alternate file of " .. input_path), vim.log.levels.WARN)
      else
        return nil
      end
    end
  end
  return vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Alternate"), _69_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return {["define-commands!"] = define_commands_21}
