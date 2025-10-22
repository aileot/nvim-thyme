local _local_1_ = require("thyme.util.fs")
local file_readable_3f = _local_1_["file-readable?"]
local read_file = _local_1_["read-file"]
local write_lua_file_21 = _local_1_["write-lua-file!"]
local Messenger = require("thyme.util.class.messenger")
local CommandMessenger = Messenger.new("command/fennel")
local _local_2_ = require("thyme.config")
local config_file_3f = _local_2_["config-file?"]
local Config = _local_2_
local DependencyLogger = require("thyme.dependency.logger")
local fennel_wrapper = require("thyme.wrapper.fennel")
local _local_3_ = require("thyme.user.command.fennel.fennel-wrapper")
local parse_cmd_file_args = _local_3_["parse-cmd-file-args"]
local mk_fennel_wrapper_command_callback = _local_3_["mk-fennel-wrapper-command-callback"]
local function compile_to_write_21(fnl_path, force_compile_3f)
  local fnl_paths
  if (0 == #fnl_path) then
    fnl_paths = {vim.api.nvim_buf_get_name(0)}
  else
    local _4_
    do
      local tbl_21_ = {}
      local i_22_ = 0
      for _, path in ipairs(fnl_path) do
        local val_23_ = vim.split(vim.fn.glob(path), "\n")
        if (nil ~= val_23_) then
          i_22_ = (i_22_ + 1)
          tbl_21_[i_22_] = val_23_
        else
        end
      end
      _4_ = tbl_21_
    end
    fnl_paths = vim.fn.flatten(_4_, 1)
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
  local or_8_ = force_compile_3f
  if not or_8_ then
    local _9_
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
      _9_ = tbl_21_
    end
    local and_12_ = _9_
    if and_12_ then
      if (0 < #existing_lua_files) then
        local _13_ = vim.fn.confirm(("The following files have already existed:\n" .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
        if (_13_ == 2) then
          and_12_ = true
        else
          local _ = _13_
          CommandMessenger["notify!"](CommandMessenger, "Abort")
          and_12_ = false
        end
      else
        and_12_ = nil
      end
    end
    or_8_ = and_12_
  end
  if or_8_ then
    local fennel_options = Config["compiler-options"]
    for fnl_path0, lua_path in pairs(path_pairs) do
      assert(not config_file_3f(fnl_path0), "Abort. Attempted to compile config file")
      local lua_lines = fennel_wrapper["compile-file"](fnl_path0, fennel_options)
      if (lua_lines == read_file(lua_path)) then
        CommandMessenger["notify!"](CommandMessenger, ("Abort. Nothing has changed in " .. fnl_path0))
      else
        local msg = (fnl_path0 .. " is compiled into " .. lua_path)
        write_lua_file_21(lua_path, lua_lines)
        CommandMessenger["notify!"](CommandMessenger, msg)
      end
    end
    return nil
  else
    return nil
  end
end
local function create_commands_21()
  local compiler_options = (Config.command["compiler-options"] or Config["compiler-options"])
  local preproc
  local or_21_ = Config.command.preproc or Config.preproc
  if not or_21_ then
    local function _22_(fnl_code, _compiler_options)
      return fnl_code
    end
    or_21_ = _22_
  end
  preproc = or_21_
  local cmd_history_opts = {method = "ignore"}
  local cb
  local function _25_(_23_)
    local fargs = _23_["fargs"]
    local should_write_file_3f = _23_["bang"]
    local _arg_24_ = _23_["mods"]
    local confirm_3f = _arg_24_["confirm"]
    local a = _23_
    local fnl_code = parse_cmd_file_args(a)
    local function _26_()
      if (0 == #fargs) then
        return {vim.fn.expand("%:p")}
      else
        return fargs
      end
    end
    local _let_27_ = _26_()
    local fnl_path = _let_27_[1]
    if should_write_file_3f then
      return compile_to_write_21(fnl_path, not confirm_3f)
    else
      local opts = {lang = "lua", ["compiler-options"] = compiler_options, preproc = preproc, ["cmd-history-opts"] = cmd_history_opts}
      local callback = mk_fennel_wrapper_command_callback(fennel_wrapper["compile-string"], opts)
      a.args = fnl_code
      return callback(a)
    end
  end
  cb = _25_
  local cmd_opts = {range = "%", nargs = "?", complete = "file", desc = "[thyme] display compiled lua result of given fnl file, or current fnl file"}
  vim.api.nvim_create_user_command("FnlFileCompile", cb, cmd_opts)
  return vim.api.nvim_create_user_command("FnlCompileFile", cb, cmd_opts)
end
return {["create-commands!"] = create_commands_21}
