local function inject_vim_cmd_arg_query_21(cmd_name, injection_language)
  local base_filetype = "vim"
  local cmd_query = (";; extends\n(user_command\n  (command_name) @_cmd\n  . (arguments) @injection.content\n  (#eq? @_cmd %q)\n  (#set! injection.language %q)\n  (#set! injection.include-children))"):format(cmd_name, injection_language)
  return vim.treesitter.query.set(base_filetype, "injections", cmd_query)
end
local function inject_dropin_query_21(injection_language)
  local base_filetype = "vim"
  local dropin_query = (";; extends\n((ERROR) @injection.content\n  (#set! injection.language %q)\n  (#set! injection.include-children))"):format(injection_language)
  return vim.treesitter.query.set(base_filetype, "injections", dropin_query)
end
return {["inject-vim-cmd-arg-query!"] = inject_vim_cmd_arg_query_21, ["inject-dropin-query!"] = inject_dropin_query_21}
