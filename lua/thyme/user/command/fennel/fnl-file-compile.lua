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
local function create_commands_21()
  local cb
  local function _4_(_3_)
    local glob_paths = _3_["fargs"]
    local force_compile_3f = _3_["bang"]
    local fnl_paths
    if (0 == #glob_paths) then
      fnl_paths = {vim.api.nvim_buf_get_name(0)}
    else
      local _5_
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
        _5_ = tbl_21_
      end
      fnl_paths = vim.fn.flatten(_5_, 1)
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
    local or_9_ = force_compile_3f
    if not or_9_ then
      local _10_
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
        _10_ = tbl_21_
      end
      local and_13_ = _10_
      if and_13_ then
        if (0 < #existing_lua_files) then
          local _14_ = vim.fn.confirm(("The following files have already existed:\n" .. table.concat(existing_lua_files, "\n") .. "\nOverride the files?"), "&No\n&yes")
          if (_14_ == 2) then
            and_13_ = true
          else
            local _ = _14_
            CommandMessenger["notify!"](CommandMessenger, "Abort")
            and_13_ = false
          end
        else
          and_13_ = nil
        end
      end
      or_9_ = and_13_
    end
    if or_9_ then
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
  cb = _4_
  local cmd_opts = {range = "%", nargs = "*", bang = true, complete = "file", desc = "Compile given fnl files, or current fnl file"}
  vim.api.nvim_create_user_command("FnlFileCompile", cb, cmd_opts)
  return vim.api.nvim_create_user_command("FnlCompileFile", cb, cmd_opts)
end
return {["create-commands!"] = create_commands_21}
