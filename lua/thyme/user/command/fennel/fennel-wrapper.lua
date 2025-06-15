local fennel = require("fennel")
local Config = require("thyme.config")
local tts = require("thyme.treesitter")
local _local_1_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_1_["apply-parinfer"]
local function make_new_cmd(new_fnl_code, _2_)
  local trailing_parens = _2_["trailing-parens"]
  local trimmed_new_fnl_code = new_fnl_code:gsub("%s*[%]}%)]*$", "")
  local last_cmd = vim.fn.histget(":", -1)
  local _3_, _4_ = last_cmd:find(trimmed_new_fnl_code, 1, true)
  if ((nil ~= _3_) and (nil ~= _4_)) then
    local idx_start = _3_
    local idx_end = _4_
    local prefix = last_cmd:sub(1, (idx_start - 1))
    local suffix = new_fnl_code:gsub("%s*$", ""):sub((idx_end - idx_start - -2))
    local trimmed_suffix
    if (trailing_parens == "omit") then
      trimmed_suffix = suffix:gsub("^[%]}%)]*", "")
    elseif (trailing_parens == "keep") then
      trimmed_suffix = suffix
    else
      local _3fval = trailing_parens
      trimmed_suffix = error(("expected one of `omit` or `keep`; got unknown value for trailing-parens: " .. vim.inspect(_3fval)))
    end
    local new_cmd = (prefix .. trimmed_new_fnl_code .. trimmed_suffix)
    return new_cmd
  else
    return nil
  end
end
local function edit_cmd_history_21(new_fnl_code, _7_)
  local method = _7_["method"]
  local opts = _7_
  local methods
  local function _8_(new_cmd)
    assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
    return assert((1 == vim.fn.histdel(":", -2)), "failed to remove the replaced fnl code")
  end
  local function _9_(new_cmd)
    return assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
  end
  local function _10_()
    --[[ "Do nothing" ]]
    return nil
  end
  methods = {overwrite = _8_, append = _9_, ignore = _10_}
  local _11_ = methods[method]
  if (nil ~= _11_) then
    local apply_method = _11_
    local new_cmd = make_new_cmd(new_fnl_code, opts)
    return apply_method(new_cmd)
  else
    local _ = _11_
    return error(("expected one of `overwrite`, `append`, or `ignore`; got unknown method " .. method))
  end
end
local function parse_cmd_buf_args(_13_)
  local path = _13_["args"]
  local line1 = _13_["line1"]
  local line2 = _13_["line2"]
  local bufnr
  if path:find("^%s*$") then
    bufnr = 0
  else
    bufnr = vim.fn.bufnr(path)
  end
  local fnl_code = table.concat(vim.api.nvim_buf_get_lines(bufnr, (line1 - 1), line2, true), "\n")
  return fnl_code
end
local function parse_cmd_file_args(_15_)
  local _arg_16_ = _15_["fargs"]
  local _3fpath = _arg_16_[1]
  local line1 = _15_["line1"]
  local line2 = _15_["line2"]
  local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
  return table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
end
local function mk_fennel_wrapper_command_callback(callback, _17_)
  local lang = _17_["lang"]
  local compiler_options = _17_["compiler-options"]
  local cmd_history_opts = _17_["cmd-history-opts"]
  local function _19_(_18_)
    local args = _18_["args"]
    local smods = _18_["smods"]
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args:gsub("\r", "\n"), {["cmd-history-opts"] = cmd_history_opts})
    local printer
    if ((not smods.silent or Config["silent-by-default"]) and (smods.unsilent or verbose_3f)) then
      printer = tts.print
    else
      local function _20_(_241)
        return _241
      end
      printer = _20_
    end
    if verbose_3f then
      local verbose_msg = (";;; Source\n%s\n;;; Result"):format(new_fnl_code)
      printer(verbose_msg, {lang = "fennel"})
    else
    end
    do
      local _23_ = {callback(new_fnl_code, compiler_options)}
      if (_23_[1] == nil) then
        printer("nil", {lang = lang})
      elseif (nil ~= _23_[1]) then
        local text = _23_[1]
        local results = _23_
        if (lang == "lua") then
          printer(text, {lang = "lua"})
        elseif (lang == "fennel") then
          for _, text0 in ipairs(results) do
            printer(fennel.view(text0, compiler_options, {lang = "fennel"}))
          end
        else
        end
      else
      end
    end
    local function _26_()
      local _27_, _28_ = pcall(vim.api.nvim_parse_cmd, vim.fn.histget(":"), {})
      if ((_27_ == true) and (nil ~= _28_)) then
        local parsed = _28_
        if parsed.cmd:find("^Fnl") then
          return edit_cmd_history_21(new_fnl_code, cmd_history_opts)
        else
          return nil
        end
      else
        return nil
      end
    end
    return vim.schedule(_26_)
  end
  return _19_
end
return {["parse-cmd-buf-args"] = parse_cmd_buf_args, ["parse-cmd-file-args"] = parse_cmd_file_args, ["mk-fennel-wrapper-command-callback"] = mk_fennel_wrapper_command_callback}
