local fennel = require("fennel")
local tts = require("thyme.wrapper.treesitter")
local fennel_wrapper = require("thyme.wrapper.fennel")
local _local_1_ = require("thyme.util.buf")
local buf_marks__3etext = _local_1_["buf-marks->text"]
local Config = require("thyme.config")
local M = {}
local Keymap = {}
Keymap.__index = Keymap
Keymap.new = function(_2_)
  local backend = _2_["backend"]
  local lang = _2_["lang"]
  local self = setmetatable({}, Keymap)
  self["_module-name"] = "thyme.user.keymap"
  self["_callback-prefix"] = "new_operator_"
  self["_operator-callback-prefix"] = "operator_"
  self._backend = backend
  self._lang = lang
  return self
end
Keymap["generate-plug-keymaps!"] = function(self, method)
  local keymap_suffix = (method .. "-" .. self._backend)
  local callback_suffix = keymap_suffix:gsub("%-", "_")
  local callback_name = (self["_callback-prefix"] .. callback_suffix)
  local callback_in_string = ("require'%s'.%s"):format(self["_module-name"], callback_name)
  local operator_callback_name = (self["_operator-callback-prefix"] .. callback_suffix)
  local operator_callback_in_string = ("require'%s'.%s"):format(self["_module-name"], operator_callback_name)
  local lhs = ("<Plug>(thyme-operator-%s)"):format(keymap_suffix)
  local rhs_2fn = ("<Cmd>set operatorfunc=v:lua.%s<CR>g@"):format(operator_callback_in_string)
  local rhs_2fx = (":lua %s('<','>')<CR>"):format(callback_in_string)
  local marks__3eprint
  local function _3_(mark1, mark2)
    local compiler_options = (Config.keymap["compiler-options"] or Config["compiler-options"])
    local eval_fn = fennel_wrapper[self._backend]
    local print_fn = tts[method]
    local val = eval_fn(buf_marks__3etext(0, mark1, mark2), compiler_options)
    local text
    if ("string" == type(val)) then
      text = val
    else
      text = fennel.view()
    end
    return print_fn(text, {lang = self._lang})
  end
  marks__3eprint = _3_
  local operator_callback
  local function _5_()
    return marks__3eprint("[", "]")
  end
  operator_callback = _5_
  vim.api.nvim_set_keymap("n", lhs, rhs_2fn, {noremap = true})
  vim.api.nvim_set_keymap("x", lhs, rhs_2fx, {noremap = true, silent = true})
  M[callback_name] = marks__3eprint
  M[operator_callback_name] = operator_callback
  return nil
end
M["define-keymaps!"] = function()
  local methods = {"echo", "print"}
  for _, method in ipairs(methods) do
    do
      local tmp_9_ = Keymap.new({backend = "compile-string", lang = "lua"})
      tmp_9_["generate-plug-keymaps!"](tmp_9_, method)
    end
    do
      local tmp_9_ = Keymap.new({backend = "eval", lang = "fennel"})
      tmp_9_["generate-plug-keymaps!"](tmp_9_, method)
    end
    do
      local tmp_9_ = Keymap.new({backend = "eval-compiler", lang = "fennel"})
      tmp_9_["generate-plug-keymaps!"](tmp_9_, method)
    end
    local tmp_9_ = Keymap.new({backend = "macrodebug", lang = "fennel"})
    tmp_9_["generate-plug-keymaps!"](tmp_9_, method)
  end
  return nil
end
return M
