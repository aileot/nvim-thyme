local tts = require("thyme.wrapper.treesitter")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.config")
local get_main_config = _local_2_["get-main-config"]
local config_file_3f = _local_2_["config-file?"]
local _local_3_ = require("thyme.utils.fs")
local file_readable_3f = _local_3_["file-readable?"]
local read_file = _local_3_["read-file"]
local write_lua_file_21 = _local_3_["write-lua-file!"]
local fennel_wrapper = require("thyme.wrapper.fennel")
local _local_4_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_4_["apply-parinfer"]
local _local_5_ = require("thyme.compiler.cache")
local clear_cache_21 = _local_5_["clear-cache!"]
local _local_6_ = require("thyme.module-map.logger")
local fnl_path__3elua_path = _local_6_["fnl-path->lua-path"]
local fennel = require("fennel")
local function open_buffer_21(buf_7cpath, _7_)
  local split = _7_["split"]
  local tab = _7_["tab"]
  local mods = _7_
  local split_3f = ((-1 ~= tab) or ("" ~= split))
  local cmd
  do
    local _8_ = type(buf_7cpath)
    if (_8_ == "number") then
      if split_3f then
        cmd = "sbuffer"
      else
        cmd = "buffer"
      end
    elseif (_8_ == "string") then
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
local function wrap_fennel_wrapper_for_command(callback, _12_)
  local lang = _12_["lang"]
  local discard_last_3f = _12_["discard-last?"]
  local compiler_options = _12_["compiler-options"]
  local overwrite_cmd_history_3f = _12_["overwrite-cmd-history?"]
  local omit_trailing_parens_3f = _12_["omit-trailing-parens?"]
  local function _14_(_13_)
    local args = _13_["args"]
    local smods = _13_["smods"]
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args, {["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f})
    if verbose_3f then
      tts.print(";;; Source")
      tts.print(new_fnl_code)
      tts.print(";;; Result")
    else
    end
    local results = {callback(new_fnl_code, compiler_options)}
    local _16_ = #results
    if (_16_ == 0) then
      return tts.print("nil", {lang = lang})
    elseif (nil ~= _16_) then
      local last_idx = _16_
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
      return nil
    else
      return nil
    end
  end
  return _14_
end
local function define_commands_21(_3fopts)
  local opts = (_3fopts or {})
  local fnl_cmd_prefix = (opts["fnl-cmd-prefix"] or "Fnl")
  local compiler_options = opts["compiler-options"]
  local overwrite_cmd_history_3f = (opts["overwrite-cmd-history?"] or true)
  local omit_trailing_parens_3f = (opts["omit-trailing-parens?"] or true)
  local function _19_()
    return vim.cmd(("tab drop " .. config_path))
  end
  vim.api.nvim_create_user_command("ThymeConfigOpen", _19_, {desc = ("[thyme] open the main config file " .. config_filename)})
  if not ("" == fnl_cmd_prefix) then
    vim.api.nvim_create_user_command(fnl_cmd_prefix, wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  else
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Eval"), wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileString"), wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f}), {nargs = "*", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  local function _23_(_21_)
    local _arg_22_ = _21_["fargs"]
    local _3fpath = _arg_22_[1]
    local line1 = _21_["line1"]
    local line2 = _21_["line2"]
    local a = _21_
    local fnl_code
    do
      local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
      fnl_code = table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
    end
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalFile"), _23_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _26_(_24_)
    local _arg_25_ = _24_["fargs"]
    local _3fpath = _arg_25_[1]
    local line1 = _24_["line1"]
    local line2 = _24_["line2"]
    local a = _24_
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
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalBuffer"), _26_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _30_(_28_)
    local _arg_29_ = _28_["fargs"]
    local _3fpath = _arg_29_[1]
    local line1 = _28_["line1"]
    local line2 = _28_["line2"]
    local a = _28_
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
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileBuffer"), _30_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"})
  local function _33_(_32_)
    local glob_paths = _32_["fargs"]
    local force_compile_3f = _32_["bang"]
    local fnl_paths
    if (0 == #glob_paths) then
      fnl_paths = {vim.api.nvim_buf_get_name(0)}
    else
      local _34_
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for _, path in ipairs(glob_paths) do
          local val_23_auto = vim.split(vim.fn.glob(path), "\n")
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            do end (tbl_21_auto)[i_22_auto] = val_23_auto
          else
          end
        end
        _34_ = tbl_21_auto
      end
      fnl_paths = vim.fn.flatten(_34_, 1)
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
    local function _38_(...)
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
          do end (tbl_21_auto)[i_22_auto] = val_23_auto
        else
        end
      end
      return tbl_21_auto
    end
    local function _43_()
      if (0 < #existing_lua_files) then
        local _41_ = vim.fn.confirm(("The following files have already existed:\n" .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
        if (_41_ == 2) then
          return true
        else
          local _ = _41_
          vim.notify("Abort")
          return false
        end
      else
        return nil
      end
    end
    if (force_compile_3f or (_38_() and _43_())) then
      local config = get_main_config()
      local fennel_options = config["compiler-options"]
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileFile"), _33_, {nargs = "*", bang = true, complete = "file", desc = "Compile given fnl files, or current fnl buffer"})
  local function _46_()
    return vim.cmd(("tab drop " .. lua_cache_prefix))
  end
  vim.api.nvim_create_user_command("ThymeCacheOpen", _46_, {desc = "[thyme] open the cache root directory"})
  local function _47_()
    if clear_cache_21() then
      return vim.notify(("Cleared cache: " .. lua_cache_prefix))
    else
      return vim.notify(("No cache files detected at " .. lua_cache_prefix))
    end
  end
  vim.api.nvim_create_user_command("ThymeCacheClear", _47_, {bar = true, bang = true, desc = "[thyme] clear the lua cache and dependency map logs"})
  local function _51_(_49_)
    local _arg_50_ = _49_["fargs"]
    local _3fpath = _arg_50_[1]
    local mods = _49_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _52_ = input_path:sub(-4)
      if (_52_ == ".fnl") then
        local _53_ = fnl_path__3elua_path(input_path)
        if (nil ~= _53_) then
          local lua_path = _53_
          output_path = lua_path
        else
          local _ = _53_
          local _54_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _54_) then
            local lua_path = _54_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_52_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _52_
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
  return vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Alternate"), _51_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return {["define-commands!"] = define_commands_21}
