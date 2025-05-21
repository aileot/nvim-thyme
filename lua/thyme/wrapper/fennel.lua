local fennel = require("fennel")
local _local_1_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_1_["apply-parinfer"]
local _local_2_ = require("thyme.util.fs")
local assert_is_fnl_file = _local_2_["assert-is-fnl-file"]
local read_file = _local_2_["read-file"]
local write_lua_file_21 = _local_2_["write-lua-file!"]
local _local_3_ = require("thyme.config")
local config_file_3f = _local_3_["config-file?"]
local Config = _local_3_
local function fnl_code__3efennel_ready(fnl_code, _3fopts)
  local compiler_options = (_3fopts or Config["compiler-options"])
  local balanced_3f_fnl_code
  if vim.g.parinfer_loaded then
    balanced_3f_fnl_code = apply_parinfer(fnl_code)
  else
    balanced_3f_fnl_code = fnl_code
  end
  if (nil == compiler_options.filename) then
    compiler_options.filename = "fennel-in-thyme"
  else
  end
  return balanced_3f_fnl_code, compiler_options
end
local function view(fnl_code, _3fopts)
  local new_fnl_code, compiler_options = fnl_code__3efennel_ready(fnl_code, _3fopts)
  return fennel.view(new_fnl_code, compiler_options)
end
local function eval(fnl_code, _3fopts)
  local new_fnl_code, compiler_options = fnl_code__3efennel_ready(fnl_code, _3fopts)
  return fennel.eval(new_fnl_code, compiler_options)
end
local function eval_compiler_2a(fnl_code, _3fopts)
  return eval(("(eval-compiler " .. fnl_code .. ")"), _3fopts)
end
local function macrodebug_2a(fnl_code, _3fopts)
  return eval(("(macrodebug " .. fnl_code .. ")"), _3fopts)
end
local function compile_string(fnl_code, _3fopts)
  local new_fnl_code, compiler_options = fnl_code__3efennel_ready(fnl_code, _3fopts)
  return fennel["compile-string"](new_fnl_code, compiler_options)
end
local function compile_buf(bufnr, _3fopts)
  assert_is_fnl_file(bufnr)
  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  local new_fnl_code, compiler_options = fnl_code__3efennel_ready(buf_lines, _3fopts)
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  compiler_options.filename = buf_name
  return fennel["compile-string"](new_fnl_code, compiler_options)
end
local function compile_file(fnl_path, _3fopts)
  assert_is_fnl_file(fnl_path)
  local fennel0 = require("fennel")
  local compiler_options = (_3fopts or Config["compiler-options"])
  local fnl_lines = read_file(fnl_path)
  compiler_options.filename = fnl_path
  return fennel0["compile-string"](fnl_lines, compiler_options)
end
local function compile_file_21(fnl_path, lua_path, _3fopts)
  assert(not config_file_3f(fnl_path), "abort. attempted to compile config file")
  local lua_lines = compile_file(fnl_path, _3fopts)
  assert(load(lua_lines))
  return write_lua_file_21(lua_path, lua_lines)
end
return {view = view, eval = eval, ["eval-compiler"] = eval_compiler_2a, macrodebug = macrodebug_2a, ["compile-string"] = compile_string, ["compile-buf"] = compile_buf, ["compile-file"] = compile_file, ["compile-file!"] = compile_file_21}
