local Path = require("thyme.utils.path")
local tts = require("thyme.wrapper.treesitter")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local config_filename = _local_1_["config-filename"]
local config_path = _local_1_["config-path"]
local _local_2_ = require("thyme.config")
local get_config = _local_2_["get-config"]
local config_file_3f = _local_2_["config-file?"]
local _local_3_ = require("thyme.utils.fs")
local file_readable_3f = _local_3_["file-readable?"]
local directory_3f = _local_3_["directory?"]
local read_file = _local_3_["read-file"]
local write_lua_file_21 = _local_3_["write-lua-file!"]
local RollbackManager = require("thyme.utils.rollback")
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
local function assert_is_file_of_thyme(path)
  local sep = (path:match("/") or "\\")
  assert((((sep .. "thyme") == path:sub(-6)) or path:find((sep .. "thyme" .. sep), 1, true)), (path .. " does not belong to thyme"))
  return path
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
  local function _20_()
    return vim.cmd(("tab drop " .. lua_cache_prefix))
  end
  vim.api.nvim_create_user_command("ThymeCacheOpen", _20_, {desc = "[thyme] open the cache root directory"})
  local function _21_()
    if clear_cache_21() then
      return vim.notify(("Cleared cache: " .. lua_cache_prefix))
    else
      return vim.notify(("No cache files detected at " .. lua_cache_prefix))
    end
  end
  vim.api.nvim_create_user_command("ThymeCacheClear", _21_, {bar = true, bang = true, desc = "[thyme] clear the lua cache and dependency map logs"})
  do
    local complete_dirs
    local function _23_(arg_lead, _cmdline, _cursorpos)
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
    complete_dirs = _23_
    local function _26_(_25_)
      local input = _25_["args"]
      local root = RollbackManager["get-root"]()
      local prefix = Path.join(root, input)
      local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
      local candidates = vim.fn.glob(glob_pattern, false, true)
      local _27_ = #candidates
      if (_27_ == 0) then
        return vim.notify(("Abort. No backup is found for " .. input))
      elseif (_27_ == 1) then
        return vim.notify(("Abort. Only one backup is found for " .. input))
      else
        local _ = _27_
        local function _28_(_241, _242)
          return (_242 < _241)
        end
        table.sort(candidates, _28_)
        local function _29_(path)
          local basename = vim.fs.basename(path)
          if RollbackManager["active-backup?"](path) then
            return (basename .. " (current)")
          else
            return basename
          end
        end
        local function _31_(_3fbackup_path)
          if _3fbackup_path then
            RollbackManager["switch-active-backup!"](_3fbackup_path)
            return vim.cmd("ThymeCacheClear")
          else
            return vim.notify("Abort selecting rollback target")
          end
        end
        return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _29_}, _31_)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackSwitch", _26_, {bar = true, nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
    local function _35_(_34_)
      local input = _34_["args"]
      local root = RollbackManager["get-root"]()
      local dir = Path.join(root, input)
      if RollbackManager["pin-backup!"](dir) then
        return vim.notify(("successfully pinned " .. dir), vim.log.levels.INFO)
      else
        return vim.notify(("failed to pin " .. dir), vim.log.levels.WARN)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackPin", _35_, {bar = true, bang = true, nargs = "?", complete = complete_dirs, desc = "[thyme] Pin currently active backup"})
    local function _38_(_37_)
      local input = _37_["args"]
      local root = RollbackManager["get-root"]()
      local dir = Path.join(root, input)
      local _39_, _40_ = pcall(RollbackManager["unpin-backup!"], dir)
      if ((_39_ == false) and (nil ~= _40_)) then
        local msg = _40_
        return vim.notify(("failed to pin %s:\n%s"):format(dir, msg), vim.log.levels.WARN)
      else
        local _ = _39_
        return vim.notify(("successfully pinned " .. dir), vim.log.levels.INFO)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackUnpin", _38_, {bar = true, bang = true, nargs = "?", complete = complete_dirs, desc = "[thyme] Unpin pinned backup"})
  end
  local function _42_()
    local files = {lua_cache_prefix, Path.join(vim.fn.stdpath("cache"), "thyme"), Path.join(vim.fn.stdpath("state"), "thyme"), Path.join(vim.fn.stdpath("data"), "thyme")}
    for _, path in ipairs(files) do
      assert_is_file_of_thyme(path)
      if directory_3f(path) then
        local _43_ = vim.fn.delete(path, "rf")
        if (_43_ == 0) then
          vim.notify(("[thyme] successfully deleted " .. path))
        else
          local _0 = _43_
          error(("[thyme] failed to delete " .. path))
        end
      else
      end
    end
    return vim.notify("[thyme] successfully uninstalled")
  end
  vim.api.nvim_create_user_command("ThymeUninstall", _42_, {desc = "[thyme] delete all the thyme's cache, state, and data files"})
  if not ("" == fnl_cmd_prefix) then
    vim.api.nvim_create_user_command(fnl_cmd_prefix, wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  else
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Eval"), wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileString"), wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f}), {nargs = "*", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  local function _49_(_47_)
    local _arg_48_ = _47_["fargs"]
    local _3fpath = _arg_48_[1]
    local line1 = _47_["line1"]
    local line2 = _47_["line2"]
    local a = _47_
    local fnl_code
    do
      local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
      fnl_code = table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
    end
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["overwrite-cmd-history?"] = overwrite_cmd_history_3f, ["omit-trailing-parens?"] = omit_trailing_parens_3f})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalFile"), _49_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _52_(_50_)
    local _arg_51_ = _50_["fargs"]
    local _3fpath = _arg_51_[1]
    local line1 = _50_["line1"]
    local line2 = _50_["line2"]
    local a = _50_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalBuffer"), _52_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _56_(_54_)
    local _arg_55_ = _54_["fargs"]
    local _3fpath = _arg_55_[1]
    local line1 = _54_["line1"]
    local line2 = _54_["line2"]
    local a = _54_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileBuffer"), _56_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"})
  local function _59_(_58_)
    local glob_paths = _58_["fargs"]
    local force_compile_3f = _58_["bang"]
    local fnl_paths
    if (0 == #glob_paths) then
      fnl_paths = {vim.api.nvim_buf_get_name(0)}
    else
      local _60_
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
        _60_ = tbl_21_auto
      end
      fnl_paths = vim.fn.flatten(_60_, 1)
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
    local or_64_ = force_compile_3f
    if not or_64_ then
      local _65_
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
        _65_ = tbl_21_auto
      end
      local and_68_ = _65_
      if and_68_ then
        if (0 < #existing_lua_files) then
          local _69_ = vim.fn.confirm(("The following files have already existed:\n" .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
          if (_69_ == 2) then
            and_68_ = true
          else
            local _ = _69_
            vim.notify("Abort")
            and_68_ = false
          end
        else
          and_68_ = nil
        end
      end
      or_64_ = and_68_
    end
    if or_64_ then
      local config = get_config()
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileFile"), _59_, {nargs = "*", bang = true, complete = "file", desc = "Compile given fnl files, or current fnl buffer"})
  local function _79_(_77_)
    local _arg_78_ = _77_["fargs"]
    local _3fpath = _arg_78_[1]
    local mods = _77_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _80_ = input_path:sub(-4)
      if (_80_ == ".fnl") then
        local _81_ = fnl_path__3elua_path(input_path)
        if (nil ~= _81_) then
          local lua_path = _81_
          output_path = lua_path
        else
          local _ = _81_
          local _82_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _82_) then
            local lua_path = _82_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_80_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _80_
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
  return vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Alternate"), _79_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return {["define-commands!"] = define_commands_21}
