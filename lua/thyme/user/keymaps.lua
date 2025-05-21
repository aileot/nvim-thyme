local fennel = require("fennel")
local tts = require("thyme.wrapper.treesitter")
local fennel_wrapper = require("thyme.wrapper.fennel")
local _local_1_ = require("thyme.utils.buf")
local buf_marks__3etext = _local_1_["buf-marks->text"]
local Config = require("thyme.config")
local M = {}
M["define-keymaps!"] = function(_3fopts)
  local module_name = "thyme.user.keymaps"
  local callback_prefix = "new_operator_"
  local operator_callback_prefix = "operator_"
  local methods = {"echo", "print"}
  local backend__3elang = {["compile-string"] = "lua", eval = "fennel", ["eval-compiler"] = "fennel", macrodebug = "fennel"}
  local opts = (_3fopts or {})
  local _3fcompiler_options = (opts["compiler-options"] or Config["compiler-options"])
  for backend, lang in pairs(backend__3elang) do
    local eval_fn = fennel_wrapper[backend]
    for _, method in ipairs(methods) do
      local print_fn = tts[method]
      local keymap_suffix = (method .. "-" .. backend)
      local callback_suffix = keymap_suffix:gsub("%-", "_")
      local callback_name = (callback_prefix .. callback_suffix)
      local callback_in_string = ("require'%s'.%s"):format(module_name, callback_name)
      local operator_callback_name = (operator_callback_prefix .. callback_suffix)
      local operator_callback_in_string = ("require'%s'.%s"):format(module_name, operator_callback_name)
      local lhs = ("<Plug>(thyme-operator-%s)"):format(keymap_suffix)
      local rhs_2fn = ("<Cmd>set operatorfunc=v:lua.%s<CR>g@"):format(operator_callback_in_string)
      local rhs_2fx = (":lua %s('<','>')<CR>"):format(callback_in_string)
      local marks__3eprint
      local function _2_(mark1, mark2)
        local val = eval_fn(buf_marks__3etext(0, mark1, mark2), _3fcompiler_options)
        local text
        if ("string" == type(val)) then
          text = val
        else
          text = fennel.view()
        end
        return print_fn(text, {lang = lang})
      end
      marks__3eprint = _2_
      local operator_callback
      local function _4_()
        return marks__3eprint("[", "]")
      end
      operator_callback = _4_
      vim.api.nvim_set_keymap("n", lhs, rhs_2fn, {noremap = true})
      vim.api.nvim_set_keymap("x", lhs, rhs_2fx, {noremap = true, silent = true})
      M[callback_name] = marks__3eprint
      M[operator_callback_name] = operator_callback
    end
  end
  return nil
end
return M
