local fennel = require("fennel")
local tts = require("thyme.treesitter")
local _local_1_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_1_["apply-parinfer"]
local function make__3fnew_cmd(new_fnl_code, _2_)
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
    local _12_ = make__3fnew_cmd(new_fnl_code, opts)
    if (nil ~= _12_) then
      local new_cmd = _12_
      return apply_method(new_cmd)
    else
      return nil
    end
  else
    local _ = _11_
    return error(("expected one of `overwrite`, `append`, or `ignore`; got unknown method " .. method))
  end
end
local function parse_cmd_buf_args(_15_)
  local path = _15_["args"]
  local line1 = _15_["line1"]
  local line2 = _15_["line2"]
  local bufnr
  if path:find("^%s*$") then
    bufnr = 0
  else
    bufnr = vim.fn.bufnr(path)
  end
  local fnl_code = table.concat(vim.api.nvim_buf_get_lines(bufnr, (line1 - 1), line2, true), "\n")
  return fnl_code
end
local function parse_cmd_file_args(_17_)
  local _arg_18_ = _17_["fargs"]
  local _3fpath = _arg_18_[1]
  local line1 = _17_["line1"]
  local line2 = _17_["line2"]
  local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
  return table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
end
local function extract_Fnl_cmdline_args(cmdline)
  local _19_, _20_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if ((_19_ == true) and (nil ~= _20_)) then
    local parsed = _20_
    if string.match(parsed.cmd, "^Fnl") then
      return table.concat(parsed.args, " ")
    else
      return extract_Fnl_cmdline_args(parsed.nextcmd)
    end
  else
    return nil
  end
end
local function mk_fennel_wrapper_command_callback(callback, _23_)
  local lang = _23_["lang"]
  local compiler_options = _23_["compiler-options"]
  local cmd_history_opts = _23_["cmd-history-opts"]
  local function _25_(_24_)
    local args = _24_["args"]
    local smods = _24_["smods"]
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args:gsub("\r", "\n"), {["cmd-history-opts"] = cmd_history_opts})
    if verbose_3f then
      local verbose_msg = (";;; Source\n%s\n;;; Result"):format(new_fnl_code)
      tts.print(verbose_msg, {lang = "fennel"})
    else
    end
    do
      local _27_ = {callback(new_fnl_code, compiler_options)}
      if (_27_[1] == nil) then
        tts.print("nil", {lang = lang})
      elseif (nil ~= _27_[1]) then
        local text = _27_[1]
        local results = _27_
        if (lang == "lua") then
          tts.print(text, {lang = "lua"})
        elseif (lang == "fennel") then
          for _, text0 in ipairs(results) do
            tts.print(fennel.view(text0, compiler_options), {lang = "fennel"})
          end
        else
        end
      else
      end
    end
    local function _30_()
      local old_cmdline = vim.fn.histget(":")
      local _31_, _32_ = pcall(vim.api.nvim_parse_cmd, old_cmdline, {})
      if ((_31_ == true) and (nil ~= _32_)) then
        local parsed = _32_
        if parsed.cmd:find("^Fnl") then
          local old_fnl_expr = extract_Fnl_cmdline_args(old_cmdline)
          local new_fnl_expr = apply_parinfer(old_fnl_expr:gsub("\r", "\n"), {["cmd-history-opts"] = cmd_history_opts})
          local new_cmdline = (parsed.cmd .. " " .. new_fnl_expr)
          return edit_cmd_history_21(new_cmdline, cmd_history_opts)
        else
          return nil
        end
      else
        return nil
      end
    end
    return vim.schedule(_30_)
  end
  return _25_
end
return {["parse-cmd-buf-args"] = parse_cmd_buf_args, ["parse-cmd-file-args"] = parse_cmd_file_args, ["mk-fennel-wrapper-command-callback"] = mk_fennel_wrapper_command_callback}
