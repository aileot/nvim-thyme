local std_config = vim.fn.stdpath("config")
local std_fnl_dir_3f = vim.uv.fs_stat(vim.fs.joinpath(std_config, "fnl"))
local use_lua_dir_3f = not std_fnl_dir_3f
local _1_
if use_lua_dir_3f then
  _1_ = "lua"
else
  _1_ = "fnl"
end
local _3_
if use_lua_dir_3f then
  _3_ = (std_config .. "/lua/?.fnlm")
else
  _3_ = nil
end
local _5_
if use_lua_dir_3f then
  _5_ = (std_config .. "/lua/?/init.fnlm")
else
  _5_ = nil
end
local _7_
if use_lua_dir_3f then
  _7_ = (std_config .. "/lua/?.fnl")
else
  _7_ = nil
end
local _9_
if use_lua_dir_3f then
  _9_ = (std_config .. "/lua/?/init-macros.fnl")
else
  _9_ = nil
end
local function _11_(...)
  if use_lua_dir_3f then
    return (std_config .. "/lua/?/init.fnl")
  else
    return nil
  end
end
local function _12_(fnl_code, _compiler_options)
  return fnl_code
end
return {["max-rollbacks"] = 5, ["compiler-options"] = {}, ["fnl-dir"] = _1_, ["macro-path"] = table.concat({"./fnl/?.fnlm", "./fnl/?/init.fnlm", "./fnl/?.fnl", "./fnl/?/init-macros.fnl", "./fnl/?/init.fnl", _3_, _5_, _7_, _9_, _11_(...)}, ";"), preproc = _12_, notifier = vim.notify, command = {["cmd-history"] = {method = "overwrite", ["trailing-parens"] = "omit"}, Fnl = {["default-range"] = 0}, FnlCompile = {["default-range"] = 0}, ["compiler-options"] = false, preproc = false}, keymap = {mappings = {}, ["compiler-options"] = false}, watch = {event = {"BufWritePost", "FileChangedShellPost"}, pattern = "*.{fnl,fnlm}", strategy = "clear-all", ["macro-strategy"] = "clear-all"}, dropin = {cmdline = {["completion-key"] = false, ["enter-key"] = false}, cmdwin = {["enter-key"] = false}}, ["disable-treesitter-highlights"] = false}
