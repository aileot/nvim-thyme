local fennel = require("fennel")
local tts = require("thyme.wrapper.treesitter")
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
local function wrap_fennel_wrapper_for_command(callback, _13_)
  local lang = _13_["lang"]
  local discard_last_3f = _13_["discard-last?"]
  local compiler_options = _13_["compiler-options"]
  local cmd_history_opts = _13_["cmd-history-opts"]
  local function _15_(_14_)
    local args = _14_["args"]
    local smods = _14_["smods"]
    local verbose_3f = (-1 < smods.verbose)
    local new_fnl_code = apply_parinfer(args:gsub("\r", "\n"), {["cmd-history-opts"] = cmd_history_opts})
    if verbose_3f then
      tts.print(";;; Source")
      tts.print(new_fnl_code)
      tts.print(";;; Result")
    else
    end
    local results = {callback(new_fnl_code, compiler_options)}
    do
      local _17_ = #results
      if (_17_ == 0) then
        tts.print("nil", {lang = lang})
      elseif (nil ~= _17_) then
        local last_idx = _17_
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
    local function _20_()
      local _21_, _22_ = pcall(vim.api.nvim_parse_cmd, vim.fn.histget(":"), {})
      if ((_21_ == true) and (nil ~= _22_)) then
        local cmdline = _22_
        if cmdline.cmd:find("^Fnl") then
          return edit_cmd_history_21(new_fnl_code, cmd_history_opts)
        else
          return nil
        end
      else
        return nil
      end
    end
    return vim.schedule(_20_)
  end
  return _15_
end
return {["wrap-fennel-wrapper-for-command"] = wrap_fennel_wrapper_for_command}
