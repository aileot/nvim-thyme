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
    local trimmed_new_fnl_code = new_fnl_code0:gsub("%s*[%]}%)]*$", "")
    local last_cmd = vim.fn.histget(":", -1)
    local _13_, _14_ = last_cmd:find(trimmed_new_fnl_code, 1, true)
    if ((nil ~= _13_) and (nil ~= _14_)) then
      local idx_start = _13_
      local idx_end = _14_
      local prefix = last_cmd:sub(1, (idx_start - 1))
      local suffix = new_fnl_code0:gsub("%s*$", ""):sub((idx_end - idx_start - -2))
      local trimmed_suffix
      do
        local _15_ = opts["trailing-parens"]
        if (_15_ == "omit") then
          trimmed_suffix = suffix:gsub("^[%]}%)]*", "")
        elseif (_15_ == "keep") then
          trimmed_suffix = suffix
        else
          local _3fval = _15_
          trimmed_suffix = error(("expected one of `omit` or `keep`; got unknown value for trailing-parens: " .. vim.inspect(_3fval)))
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
    return assert((1 == vim.fn.histdel(":", -2)), "failed to remove the replaced fnl code")
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
    local results = {callback(new_fnl_code, compiler_options)}
    do
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
    local function _30_()
      return edit_cmd_history_21(new_fnl_code, cmd_history_opts)
    end
    return vim.schedule(_30_)
  end
  return _25_
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
  local function _32_()
    return vim.cmd(("tab drop " .. config_path))
  end
  vim.api.nvim_create_user_command("ThymeConfigOpen", _32_, {desc = ("[thyme] open the main config file " .. config_filename)})
  local function _33_()
    return vim.cmd(("tab drop " .. lua_cache_prefix))
  end
  vim.api.nvim_create_user_command("ThymeCacheOpen", _33_, {desc = "[thyme] open the cache root directory"})
  local function _34_()
    if clear_cache_21() then
      return vim.notify(("Cleared cache: " .. lua_cache_prefix))
    else
      return vim.notify(("No cache files detected at " .. lua_cache_prefix))
    end
  end
  vim.api.nvim_create_user_command("ThymeCacheClear", _34_, {bar = true, bang = true, desc = "[thyme] clear the lua cache and dependency map logs"})
  do
    local complete_dirs
    local function _36_(arg_lead, _cmdline, _cursorpos)
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
    complete_dirs = _36_
    local function _39_(_38_)
      local input = _38_["args"]
      local root = RollbackManager["get-root"]()
      local prefix = Path.join(root, input)
      local glob_pattern = Path.join(prefix, "*.{lua,fnl}")
      local candidates = vim.fn.glob(glob_pattern, false, true)
      local _40_ = #candidates
      if (_40_ == 0) then
        return vim.notify(("Abort. No backup is found for " .. input))
      elseif (_40_ == 1) then
        return vim.notify(("Abort. Only one backup is found for " .. input))
      else
        local _ = _40_
        local function _41_(_241, _242)
          return (_242 < _241)
        end
        table.sort(candidates, _41_)
        local function _42_(path)
          local basename = vim.fs.basename(path)
          if RollbackManager["active-backup?"](path) then
            return (basename .. " (current)")
          else
            return basename
          end
        end
        local function _44_(_3fbackup_path)
          if _3fbackup_path then
            RollbackManager["switch-active-backup!"](_3fbackup_path)
            return vim.cmd("ThymeCacheClear")
          else
            return vim.notify("Abort selecting rollback target")
          end
        end
        return vim.ui.select(candidates, {prompt = ("Select rollback for %s: "):format(input), format_item = _42_}, _44_)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackSwitch", _39_, {bar = true, nargs = 1, complete = complete_dirs, desc = "[thyme] Prompt to select rollback for compile error"})
    local function _48_(_47_)
      local input = _47_["args"]
      local root = RollbackManager["get-root"]()
      local dir = Path.join(root, input)
      if RollbackManager["mount-backup!"](dir) then
        return vim.notify(("successfully mounted " .. dir), vim.log.levels.INFO)
      else
        return vim.notify(("failed to mount " .. dir), vim.log.levels.WARN)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackMount", _48_, {bar = true, nargs = 1, complete = complete_dirs, desc = "[thyme] Mount currently active backup"})
    local function _51_(_50_)
      local input = _50_["args"]
      local root = RollbackManager["get-root"]()
      local dir = Path.join(root, input)
      local _52_, _53_ = pcall(RollbackManager["unmount-backup!"], dir)
      if ((_52_ == false) and (nil ~= _53_)) then
        local msg = _53_
        return vim.notify(("failed to mount %s:\n%s"):format(dir, msg), vim.log.levels.WARN)
      else
        local _ = _52_
        return vim.notify(("successfully mounted " .. dir), vim.log.levels.INFO)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackUnmount", _51_, {bar = true, nargs = "?", complete = complete_dirs, desc = "[thyme] Unmount mounted backup"})
    local function _55_()
      local _56_, _57_ = pcall(RollbackManager["unmount-backup-all!"])
      if ((_56_ == false) and (nil ~= _57_)) then
        local msg = _57_
        return vim.notify(("failed to mount backups:\n%s"):format(msg), vim.log.levels.WARN)
      else
        local _ = _56_
        return vim.notify("successfully mounted backups", vim.log.levels.INFO)
      end
    end
    vim.api.nvim_create_user_command("ThymeRollbackUnmountAll", _55_, {bar = true, nargs = 0, desc = "[thyme] Unmount all the mounted backups"})
  end
  local function _59_()
    local files = {lua_cache_prefix, Path.join(vim.fn.stdpath("cache"), "thyme"), Path.join(vim.fn.stdpath("state"), "thyme"), Path.join(vim.fn.stdpath("data"), "thyme")}
    for _, path in ipairs(files) do
      assert_is_file_of_thyme(path)
      if directory_3f(path) then
        local _60_ = vim.fn.delete(path, "rf")
        if (_60_ == 0) then
          vim.notify(("[thyme] successfully deleted " .. path))
        else
          local _0 = _60_
          error(("[thyme] failed to delete " .. path))
        end
      else
      end
    end
    return vim.notify("[thyme] successfully uninstalled")
  end
  vim.api.nvim_create_user_command("ThymeUninstall", _59_, {desc = "[thyme] delete all the thyme's cache, state, and data files"})
  if not ("" == fnl_cmd_prefix) then
    vim.api.nvim_create_user_command(fnl_cmd_prefix, wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  else
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Eval"), wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", complete = "lua", desc = "[thyme] evaluate the following fennel expression, and display the results"})
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileString"), wrap_fennel_wrapper_for_command(fennel_wrapper["compile-string"], {lang = "lua", ["discard-last?"] = true, ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts}), {nargs = "*", desc = "[thyme] display the compiled lua results of the following fennel expression"})
  local function _66_(_64_)
    local _arg_65_ = _64_["fargs"]
    local _3fpath = _arg_65_[1]
    local line1 = _64_["line1"]
    local line2 = _64_["line2"]
    local a = _64_
    local fnl_code
    do
      local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
      fnl_code = table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
    end
    local callback = wrap_fennel_wrapper_for_command(fennel_wrapper.eval, {lang = "fennel", ["compiler-options"] = compiler_options, ["cmd-history-opts"] = cmd_history_opts})
    a.args = fnl_code
    return callback(a)
  end
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalFile"), _66_, {range = "%", nargs = "?", complete = "file", desc = "[thyme] evaluate given file, or current file, and display the results"})
  local function _69_(_67_)
    local _arg_68_ = _67_["fargs"]
    local _3fpath = _arg_68_[1]
    local line1 = _67_["line1"]
    local line2 = _67_["line2"]
    local a = _67_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "EvalBuffer"), _69_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] evaluate given buffer, or current buffer, and display the results"})
  local function _73_(_71_)
    local _arg_72_ = _71_["fargs"]
    local _3fpath = _arg_72_[1]
    local line1 = _71_["line1"]
    local line2 = _71_["line2"]
    local a = _71_
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileBuffer"), _73_, {range = "%", nargs = "?", complete = "buffer", desc = "[thyme] display the compiled lua results of current buffer"})
  local function _76_(_75_)
    local glob_paths = _75_["fargs"]
    local force_compile_3f = _75_["bang"]
    local fnl_paths
    if (0 == #glob_paths) then
      fnl_paths = {vim.api.nvim_buf_get_name(0)}
    else
      local _77_
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
        _77_ = tbl_21_auto
      end
      fnl_paths = vim.fn.flatten(_77_, 1)
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
    local or_81_ = force_compile_3f
    if not or_81_ then
      local _82_
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
        _82_ = tbl_21_auto
      end
      local and_85_ = _82_
      if and_85_ then
        if (0 < #existing_lua_files) then
          local _86_ = vim.fn.confirm(("The following files have already existed:\n" .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
          if (_86_ == 2) then
            and_85_ = true
          else
            local _ = _86_
            vim.notify("Abort")
            and_85_ = false
          end
        else
          and_85_ = nil
        end
      end
      or_81_ = and_85_
    end
    if or_81_ then
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
  vim.api.nvim_create_user_command((fnl_cmd_prefix .. "CompileFile"), _76_, {nargs = "*", bang = true, complete = "file", desc = "Compile given fnl files, or current fnl buffer"})
  local function _96_(_94_)
    local _arg_95_ = _94_["fargs"]
    local _3fpath = _arg_95_[1]
    local mods = _94_["smods"]
    local input_path = vim.fn.expand((_3fpath or "%:p"))
    local output_path
    do
      local _97_ = input_path:sub(-4)
      if (_97_ == ".fnl") then
        local _98_ = fnl_path__3elua_path(input_path)
        if (nil ~= _98_) then
          local lua_path = _98_
          output_path = lua_path
        else
          local _ = _98_
          local _99_ = (input_path:sub(1, -4) .. "lua")
          if (nil ~= _99_) then
            local lua_path = _99_
            if file_readable_3f(lua_path) then
              output_path = lua_path
            else
              output_path = lua_path:gsub("/fnl/", "/lua/")
            end
          else
            output_path = nil
          end
        end
      elseif (_97_ == ".lua") then
        if vim.startswith(input_path, lua_cache_prefix) then
          output_path = vim.api.nvim_get_runtime_file(input_path:sub(#lua_cache_prefix):gsub("%.lua$", ".fnl"):gsub("^", "*"), false)[1]
        else
          output_path = vim.fn.glob(input_path:gsub("/lua/", "/*/"):gsub("%.lua$", ".fnl"), false)
        end
      else
        local _ = _97_
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
  return vim.api.nvim_create_user_command((fnl_cmd_prefix .. "Alternate"), _96_, {nargs = "?", complete = "file", desc = "[thyme] alternate fnl<->lua"})
end
return {["define-commands!"] = define_commands_21}
