local fennel = require("fennel")
local tts = require("thyme.treesitter")
local _local_1_ = require("thyme.wrapper.parinfer")
local apply_parinfer = _local_1_["apply-parinfer"]
local function make__3fnew_cmd(new_fnl_code, _2_)
  local trailing_parens = _2_["trailing-parens"]
  local trimmed_new_fnl_code = new_fnl_code:gsub("%s*[%]}%)]*$", "")
  local last_cmd = vim.fn.histget(":", -1)
  local case_3_, case_4_ = last_cmd:find(trimmed_new_fnl_code, 1, true)
  if ((nil ~= case_3_) and (nil ~= case_4_)) then
    local idx_start = case_3_
    local idx_end = case_4_
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
  local method = _7_.method
  local opts = _7_
  local methods
  local function _8_(new_cmd)
    assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
    return assert((1 == vim.fn.histdel(":", -2)), "failed to remove the replaced fnl code")
  end
  local function _9_(new_cmd)
    return assert((1 == vim.fn.histadd(":", new_cmd)), "failed to add new fnl code")
  end
  methods = {overwrite = _8_, append = _9_, ignore = false}
  local case_10_ = methods[method]
  if (case_10_ == false) then
    --[[ "Do nothing" ]]
    return nil
  elseif (nil ~= case_10_) then
    local apply_method = case_10_
    local case_11_ = make__3fnew_cmd(new_fnl_code, opts)
    if (nil ~= case_11_) then
      local new_cmd = case_11_
      return apply_method(new_cmd)
    else
      return nil
    end
  else
    local _ = case_10_
    return error(("expected one of `overwrite`, `append`, or `ignore`; got unknown method " .. method))
  end
end
local function parse_cmd_buf_args(_14_)
  local path = _14_.args
  local line1 = _14_.line1
  local line2 = _14_.line2
  local bufnr
  if path:find("^%s*$") then
    bufnr = 0
  else
    bufnr = vim.fn.bufnr(path)
  end
  local fnl_code = table.concat(vim.api.nvim_buf_get_lines(bufnr, (line1 - 1), line2, true), "\n")
  return fnl_code
end
local function parse_cmd_file_args(_16_)
  local _arg_17_ = _16_.fargs
  local _3fpath = _arg_17_[1]
  local line1 = _16_.line1
  local line2 = _16_.line2
  local full_path = vim.fn.fnamemodify(vim.fn.expand((_3fpath or "%:p")), ":p")
  return table.concat(vim.list_slice(vim.fn.readfile(full_path, "", line2), line1), "\n")
end
local function extract_Fnl_cmdline_args(cmdline)
  local case_18_, case_19_ = pcall(vim.api.nvim_parse_cmd, cmdline, {})
  if ((case_18_ == true) and (nil ~= case_19_)) then
    local parsed = case_19_
    if string.match(parsed.cmd, "^Fnl") then
      return table.concat(parsed.args, " ")
    else
      return extract_Fnl_cmdline_args(parsed.nextcmd)
    end
  else
    return nil
  end
end
local function mk_fennel_wrapper_command_callback(callback, _22_)
  local lang = _22_.lang
  local compiler_options = _22_["compiler-options"]
  local cmd_history_opts = _22_["cmd-history-opts"]
  local function _24_(_23_)
    local args = _23_.args
    local smods = _23_.smods
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args:gsub("\r", "\n"), {["cmd-history-opts"] = cmd_history_opts})
    if verbose_3f then
      local verbose_msg = (";;; Source\n%s\n;;; Result"):format(new_fnl_code)
      tts.print(verbose_msg, {lang = "fennel"})
    else
    end
    do
      local case_26_ = {callback(new_fnl_code, compiler_options)}
      if (case_26_[1] == nil) then
        tts.print("nil", {lang = lang})
      elseif (nil ~= case_26_[1]) then
        local text = case_26_[1]
        local results = case_26_
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
    local function _29_()
      local old_cmdline = vim.fn.histget(":")
      local case_30_, case_31_ = pcall(vim.api.nvim_parse_cmd, old_cmdline, {})
      if ((case_30_ == true) and (nil ~= case_31_)) then
        local parsed = case_31_
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
    return vim.schedule(_29_)
  end
  return _24_
end
return {["parse-cmd-buf-args"] = parse_cmd_buf_args, ["parse-cmd-file-args"] = parse_cmd_file_args, ["mk-fennel-wrapper-command-callback"] = mk_fennel_wrapper_command_callback}
