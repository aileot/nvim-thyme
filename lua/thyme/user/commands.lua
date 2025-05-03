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
local RollbackManager = require("thyme.rollback")
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
local function edit_cmd_history_21(new_fnl_code, opts)
  local make_new_cmd
  local function _12_(new_fnl_code0)
    local trimmed_new_fnl_code = new_fnl_code0:gsub("[%]}%)]$", "")
    local last_cmd = vim.fn.histget(":", -1)
    local _13_, _14_ = string.find(last_cmd, trimmed_new_fnl_code, 1, true)
    if ((nil ~= _13_) and (nil ~= _14_)) then
      local idx_start = _13_
      local idx_end = _14_
      local prefix = last_cmd:sub(1, (idx_start - 1))
      local suffix = last_cmd:sub((idx_end + 1))
      local trimmed_suffix
      do
        local _15_ = opts["trailing-parens"]
        if (_15_ == "omit") then
          trimmed_suffix = suffix:gsub("^%s*[%]}%)]*", "")
        elseif (_15_ == "keep") then
          trimmed_suffix = suffix
        else
          local _ = _15_
          trimmed_suffix = error("expected one of `omit` or `keep`; got unknown value for trailing-parens ", opts["trailing-parens"])
        end
      end
      local new_cmd = (prefix .. trimmed_new_fnl_code .. trimmed_suffix)
      return new_cmd
    else
      return nil
    end
  end
  make_new_cmd = _12_
  local methods
  local function _18_(new_cmd)
    assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
    return assert((1 == vim.fn.histdel(":", new_cmd)), "failed to remove the replaced fnl code")
  end
  local function _19_(new_cmd)
    return assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
  end
  local function _20_()
    --[[ "Do nothing" ]]
    return nil
  end
  methods = {overwrite = _18_, append = _19_, ignore = _20_}
  local _21_ = methods[opts.method]
  if (nil ~= _21_) then
    local apply_method = _21_
    local new_cmd = make_new_cmd(new_fnl_code)
    return apply_method(new_cmd)
  else
    local _ = _21_
    return error(("expected one of `overwrite`, `append`, or `ignore`; got unknown method " .. opts.method))
  end
end
local function wrap_fennel_wrapper_for_command(callback, _23_)
  local lang = _23_["lang"]
  local discard_last_3f = _23_["discard-last?"]
  local compiler_options = _23_["compiler-options"]
  local cmd_history_opts = _23_["cmd-history-opts"]
  local function _25_(_24_)
    local args = _24_["args"]
    local smods = _24_["smods"]
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args, {["cmd-history-opts"] = cmd_history_opts})
    if verbose_3f then
      tts.print(";;; Source")
      tts.print(new_fnl_code)
      tts.print(";;; Result")
    else
    end
    do
      local results = {callback(new_fnl_code, compiler_options)}
      local _27_ = #results
      if (_27_ == 0) then
        tts.print("nil", {lang = lang})
      elseif (nil ~= _27_) then
        local last_idx = _27_
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
    if cmd_history_opts then
      local function _30_()
        return edit_cmd_history_21(new_fnl_code, cmd_history_opts)
      end
      return vim.schedule(_30_)
    else
      return nil
    end
  end
  return _25_
end
local function assert_is_file_of_thyme(path)
  local sep = (path:match("/") or "\\")
  assert((((sep .. "thyme") == path:sub(-6)) or path:find((sep .. "thyme" .. sep), 1, true)), (path .. " does not belong to thyme"))
  return path
end
local function define_commands_21(_3fopts)
  local config = get_config()
  local opts
  if _3fopts then
    opts = vim.tbl_deep_extend("force", config.command, _3fopts)
  else
    opts = config.command
  end
  local fnl_cmd_prefix = opts["fnl-cmd-prefix"]
  local compiler_options = opts["compiler-options"]
  local cmd_history_opts = opts["cmd-history"]
  local function _33_()
    return vim.cmd(("tab drop " .. config_path))
  end
  vim.api.nvim_create_user_command("ThymeConfigOpen", _33_, {desc = ("[thyme] open the main config file " .. config_filename)})
  local function _34_()
    return vim.cmd(("tab drop " .. lua_cache_prefix))
  end
  vim.api.nvim_create_user_command("ThymeCacheOpen", _34_, {desc = "[thyme] open the cache root directory"})
  local function _35_()
    if clear_cache_21() then
      return vim.notify(("Cleared cache: " .. lua_cache_prefix))
    else
      return vim.notify(("No cache files detected at " .. lua_cache_prefix))
    end
  end
  vim.api.nvim_create_user_command("ThymeCacheClear", _35_, {bar = true, bang = true, desc = "[thyme] clear the lua cache and dependency map logs"})
  do
    local complete_dirs
    local function _37_(arg_lead, _cmdline, _cursorpos)
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
    complete_dirs = _37_
    local function _40_(_39_)
      local input = _39_["args"]
      local root = RollbackManager["get-root"]()
      local prefix = Path.join(root, input)
      local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
      local candidates = vim.fn.glob(glob_pattern, false, true)
      local _41_ = #candidates
      if (_41_ == 0) then
        return vim.notify(("Abort. No backup is found for " .. input))
      elseif (_41_ == 1) then
        return vim.notify(("Abort. Only one backup is found for " .. input))
      else
        local _ = _41_
        local function _42_(_241, _242)
          return (_242 < _241)
        end
        table.sort(candidates, _42_)
        local function _43_(path)
          local basename = vim.fs.basename(path)
          if RollbackManager["active-backup?"](path) then
            return (basename .. " (current)")
          else
            return basename
          end
        end
        local function _45_(_3fbackup_path)
          if _3fbackup_path then
            RollbackManager["switch-active-backup!"](_3fbackup_path)
            return vim.cmd("ThymeCacheClear")
          else
            return vim.notify("Abort selecting rollback target")
          end
        end
        return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _43_}, _45_)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackSwitch", _40_, {bar = true, nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
    local function _49_(_48_)
      local input = _48_["args"]
      local root = RollbackManager["get-root"]()
      local dir = Path.join(root, input)
      if RollbackManager["mount-backup!"](dir) then
        return vim.notify(("successfully mounted " .. dir), vim.log.levels.INFO)
      else
        return vim.notify(("failed to mount " .. dir), vim.log.levels.WARN)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackMount", _49_, {bar = true, nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
    local function _52_(_51_)
      local input = _51_["args"]
      local root = RollbackManager["get-root"]()
      local dir = Path.join(root, input)
      local _53_, _54_ = pcall(RollbackManager["unmount-backup!"], dir)
      if ((_53_ == false) and (nil ~= _54_)) then
        local msg = _54_
        return vim.notify(("failed to mount %s:\n%s"):format(dir, msg), vim.log.levels.WARN)
      else
        local _ = _53_
        return vim.notify(("successfully mounted " .. dir), vim.log.levels.INFO)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackUnmount", _52_, {bar = true, nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
    local function _56_()
      local _57_, _58_ = pcall(RollbackManager["unmount-backup-all!"])
      if ((_57_ == false) and (nil ~= _58_)) then
        local msg = _58_
        return vim.notify(("failed to mount backups:\n%s"):format(msg), vim.log.levels.WARN)
      else
        local _ = _57_
        return vim.notify("successfully mounted backups", vim.log.levels.INFO)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _56_, {bar = true, nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
  end
  local function _60_()
    local files = {lua_cache_prefix, Path.join(vim.fn.stdpath("cache"), "thyme"), Path.join(vim.fn.stdpath("state"), "thyme"), Path.join(vim.fn.stdpath("data"), "thyme")}
    for _, path in ipairs(files) do
      assert_is_file_of_thyme(path)
      if directory_3f(path) then
        local _61_ = vim.fn.delete(path, "rf")
        if (_61_ == 0) then
          vim.notify(("[thyme] successfully deleted " .. path))
        else
          local _0 = _61_
          error(("[thyme] failed to delete " .. path))
        end
      else
      end
    end
    return vim.notify("[thyme] successfully uninstalled")
  end
  vim.api.nvim_create_user_command("ThymeUninstall", _60_, {desc = "[thyme] delete all the thyme's cache, state, and data files"})
  if not ("" == fnl_cmd_prefix) then
    vim.api.nvim_create_user_command(fnl_cmd_prefix, wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  else
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Eval"), wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileString"), wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  local function _67_(_65_)
    local _arg_66_ = _65_["fargs"]
    local _3fpath = _arg_66_[1]
    local line1 = _65_["line1"]
    local line2 = _65_["line2"]
    local a = _65_
    local fnl_code
    do
      local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
      fnl_code = table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
    end
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalFile"), _67_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _70_(_68_)
    local _arg_69_ = _68_["fargs"]
    local _3fpath = _arg_69_[1]
    local line1 = _68_["line1"]
    local line2 = _68_["line2"]
    local a = _68_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalBuffer"), _70_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _74_(_72_)
    local _arg_73_ = _72_["fargs"]
    local _3fpath = _arg_73_[1]
    local line1 = _72_["line1"]
    local line2 = _72_["line2"]
    local a = _72_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileBuffer"), _74_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"})
  local function _77_(_76_)
    local glob_paths = _76_["fargs"]
    local force_compile_3f = _76_["bang"]
    local fnl_paths
    if (0 == #glob_paths) then
      fnl_paths = {vim.api.nvim_buf_get_name(0)}
    else
      local _78_
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
        _78_ = tbl_21_auto
      end
      fnl_paths = vim.fn.flatten(_78_, 1)
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
    local or_82_ = force_compile_3f
    if not or_82_ then
      local _83_
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
        _83_ = tbl_21_auto
      end
      local and_86_ = _83_
      if and_86_ then
        if (0 < #existing_lua_files) then
          local _87_ = vim.fn.confirm(("The following files have already existed:\n" .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
          if (_87_ == 2) then
            and_86_ = true
          else
            local _ = _87_
            vim.notify("Abort")
            and_86_ = false
          end
        else
          and_86_ = nil
        end
      end
      or_82_ = and_86_
    end
    if or_82_ then
      local config0 = get_config()
      local fennel_options = config0["compiler-options"]
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileFile"), _77_, {nargs = "*", bang = true, complete = "file", desc = "Compile given fnl files, or current fnl buffer"})
  local function _97_(_95_)
    local _arg_96_ = _95_["fargs"]
    local _3fpath = _arg_96_[1]
    local mods = _95_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _98_ = input_path:sub(-4)
      if (_98_ == ".fnl") then
        local _99_ = fnl_path__3elua_path(input_path)
        if (nil ~= _99_) then
          local lua_path = _99_
          output_path = lua_path
        else
          local _ = _99_
          local _100_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _100_) then
            local lua_path = _100_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_98_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _98_
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
  return vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Alternate"), _97_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return {["define-commands!"] = define_commands_21}
