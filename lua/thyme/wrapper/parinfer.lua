local ffi = require("ffi")
local Path = require("thyme.util.path")
local _local_1_ = require("thyme.wrapper.nvim")
local get_runtime_files = _local_1_["get-runtime-files"]
local json_encode = vim.json["encode"]
local json_decode = vim.json["decode"]
local cache = {["parinfer-loader"] = nil}
local vim_var_suffixes
do
  local vim_var_prefix = "parinfer_"
  local tbl_16_ = {}
  for k, v in pairs({mode = "mode", enabled = "enabled", trail_highlight = "trail_highlight", trail_highlight_group = "trail_highlight_group", force_balance = "forceBalance", comment_char = "commentChar", string_delimiters = "stringDelimiters", lisp_vline_symbols = "lispVlineSymbols", lisp_block_comments = "lispBlockComments", guile_block_comments = "guileBlockComments", scheme_sexp_comments = "schemeSexpComments", janet_long_strings = "janetLongStrings"}) do
    local k_17_, v_18_ = (vim_var_prefix .. k), v
    if ((k_17_ ~= nil) and (v_18_ ~= nil)) then
      tbl_16_[k_17_] = v_18_
    else
    end
  end
  vim_var_suffixes = tbl_16_
end
local function vim_var__3elib_opts(_3fval)
  if ("number" == type(_3fval)) then
    return (1 == _3fval)
  else
    return _3fval
  end
end
local function collect_gvar_options()
  local tbl_16_ = {}
  for vim_var_suffix, lib_opt_name in pairs(vim_var_suffixes) do
    local k_17_, v_18_ = lib_opt_name, vim_var__3elib_opts(vim.g[vim_var_suffix])
    if ((k_17_ ~= nil) and (v_18_ ~= nil)) then
      tbl_16_[k_17_] = v_18_
    else
    end
  end
  return tbl_16_
end
local function search_parinfer_lib()
  local parinfer_lib
  do
    local _5_ = ffi.os:lower()
    if (_5_ == "windows") then
      parinfer_lib = "parinfer_rust.dll"
    elseif (_5_ == "osx") then
      parinfer_lib = "libparinfer_rust.dylib"
    else
      local _ = _5_
      parinfer_lib = "libparinfer_rust.so"
    end
  end
  local rtp_paths_to_parinfer_lib = {Path.join("target", "release", parinfer_lib), parinfer_lib}
  local _7_ = get_runtime_files(rtp_paths_to_parinfer_lib, false)
  if ((_G.type(_7_) == "table") and (nil ~= _7_[1])) then
    local lib = _7_[1]
    return lib
  else
    local _ = _7_
    return error(("failed to find %s. Please make sure to install %s iu your &runtimepath"):format(parinfer_lib, "https://github.com/eraserhd/parinfer-rust"))
  end
end
local function load_parinfer()
  local lib = search_parinfer_lib()
  local parinfer_lib = ffi.load(lib)
  ffi.cdef("char *run_parinfer(const char *json);")
  local function _9_(request)
    return json_decode(ffi.string(parinfer_lib.run_parinfer(json_encode(request))))
  end
  return _9_
end
local function apply_parinfer(text, _3fopts)
  if (nil == cache["parinfer-loader"]) then
    cache["parinfer-loader"] = load_parinfer()
  else
  end
  local opts = collect_gvar_options()
  local options
  if _3fopts then
    options = vim.tbl_extend("keep", _3fopts, opts)
  else
    options = opts
  end
  local request = {text = text, options = options, mode = (opts.mode or "smart")}
  local result = cache["parinfer-loader"](request)
  if result.success then
    return result.text
  else
    local msg = ("Error in applying parinfer to the text:\n%s\nPassed Options:\n%s\nParinfer Result:\n%s"):format(text, vim.inspect(options), vim.inspect(result))
    return error(msg)
  end
end
return {["apply-parinfer"] = apply_parinfer}
