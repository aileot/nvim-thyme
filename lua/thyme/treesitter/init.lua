local _local_1_ = require("thyme.treesitter.chunks")
local text__3ehl_chunks = _local_1_["text->hl-chunks"]
local function echo(text, _3fopts)
  if (nil == text) then
    _G.error("Missing argument text on fnl/thyme/treesitter/init.fnl:3", 2)
  else
  end
  local hl_chunks = text__3ehl_chunks(text, _3fopts)
  return vim.api.nvim_echo(hl_chunks, false, {})
end
local function print(text, _3fopts)
  if (nil == text) then
    _G.error("Missing argument text on fnl/thyme/treesitter/init.fnl:9", 2)
  else
  end
  local hl_chunks = text__3ehl_chunks(text, _3fopts)
  return vim.api.nvim_echo(hl_chunks, true, {})
end
return {echo = echo, print = print}
