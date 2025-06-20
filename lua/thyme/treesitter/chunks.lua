local _local_1_ = require("thyme.util.general")
local validate_type = _local_1_["validate-type"]
local new_matrix = _local_1_["new-matrix"]
local _local_2_ = require("thyme.util.iterator")
local char_by_char = _local_2_["char-by-char"]
local uncouple_substrings = _local_2_["uncouple-substrings"]
local Config = require("thyme.config")
local ts = vim.treesitter
local hl_cache = {}
local hl_chunk_cache = new_matrix()
local idx_empty_hl_name = true
local special_chunk = {whitespace = {" "}, newline = {"\n"}}
local function set_hl_chunk_cache_21(text, _3fhl_name)
  local _3fhl_group
  if _3fhl_name then
    local _3fgroup = nil
    for hl_name in uncouple_substrings(_3fhl_name, ".") do
      if _3fgroup then break end
      if vim.api.nvim_get_hl_id_by_name(hl_name) then
        _3fgroup = hl_name
      else
        _3fgroup = nil
      end
    end
    _3fhl_group = _3fgroup
  else
    _3fhl_group = nil
  end
  local hl_chunk = {text, _3fhl_group}
  local idx = (_3fhl_name or idx_empty_hl_name)
  hl_chunk_cache[text][idx] = hl_chunk
  return hl_chunk
end
local function get_hl_chunk_cache(text, _3fhl_name)
  local idx = (_3fhl_name or idx_empty_hl_name)
  local t_5_ = hl_chunk_cache
  if (nil ~= t_5_) then
    t_5_ = t_5_[text]
  else
  end
  if (nil ~= t_5_) then
    t_5_ = t_5_[idx]
  else
  end
  return t_5_
end
local function determine_hl_chunk(text, _3fhl_name)
  return (get_hl_chunk_cache(text, _3fhl_name) or set_hl_chunk_cache_21(text, _3fhl_name))
end
local priority_matrix = {}
local function initialize_priority_matrix_21(row, col)
  priority_matrix = new_matrix(row, col, 0)
  return nil
end
local function update_hl_chunk_matrix_21(hl_chunk_matrix, text, _3fhl_name, metadata, row01, col01)
  local priority = (tonumber(metadata.priority) or 0)
  local row1 = (row01 + 1)
  local col1 = (col01 + 1)
  local last_priority = (priority_matrix[row1][col1] or 0)
  if (last_priority <= priority) then
    local row = row1
    local col = col1
    for _, char in char_by_char(text) do
      priority_matrix[row][col] = priority
      hl_chunk_matrix[row][col] = determine_hl_chunk(char, _3fhl_name)
      if ("\n" == char) then
        row = (row + 1)
        col = 1
      else
        col = (col + 1)
      end
    end
    return nil
  else
    return nil
  end
end
local function compose_hl_chunks(text, lang_tree)
  local top_row0 = 0
  local top_col0 = 0
  local bottom_row0 = -1
  local end_row = #vim.split(text, "\n", {plain = true})
  local end_col = vim.go.columns
  local hl_chunk_matrix = new_matrix(end_row, end_col, special_chunk.whitespace)
  local cb
  local function _10_(ts_tree, tree)
    if ts_tree then
      local lang = tree:lang()
      local hl_query
      local or_11_ = hl_cache[lang]
      if not or_11_ then
        local hlq = ts.query.get(lang, "highlights")
        hl_cache[lang] = hlq
        or_11_ = hlq
      end
      hl_query = or_11_
      local iter = hl_query:iter_captures(ts_tree:root(), text, top_row0, bottom_row0)
      for id, node, metadata in iter do
        local _13_ = hl_query.captures[id]
        if ((_13_ == "spell") or (_13_ == "nospell")) then
        else
          local and_14_ = (nil ~= _13_)
          if and_14_ then
            local capture = _13_
            and_14_ = not vim.startswith(capture, "_")
          end
          if and_14_ then
            local capture = _13_
            local txt = ts.get_node_text(node, text)
            local hl_name = ("@" .. capture)
            local row01, col01 = node:range()
            update_hl_chunk_matrix_21(hl_chunk_matrix, txt, hl_name, metadata, row01, col01)
          else
          end
        end
      end
      return nil
    else
      return nil
    end
  end
  cb = _10_
  initialize_priority_matrix_21(end_row, end_col)
  do
    local text_with_newline
    if ("\n" == text:sub(-1)) then
      text_with_newline = text
    else
      text_with_newline = (text .. "\n")
    end
    update_hl_chunk_matrix_21(hl_chunk_matrix, text_with_newline, nil, {}, top_row0, top_col0)
  end
  do
    lang_tree:parse()
    lang_tree:for_each_tree(cb)
  end
  local hl_chunks = {}
  for i = 1, end_row do
    for j = 1, end_col do
      if ("\n" == hl_chunk_matrix[i][j][1]) then break end
      table.insert(hl_chunks, hl_chunk_matrix[i][j])
    end
    table.insert(hl_chunks, special_chunk.newline)
  end
  if ("\n" ~= text:sub(-1)) then
    table.remove(hl_chunks)
  else
  end
  return hl_chunks
end
local function text__3ehl_chunks(text, _3fopts)
  _G.assert((nil ~= text), "Missing argument text on fnl/thyme/treesitter/chunks.fnl:128")
  validate_type("string", text)
  if Config["disable-treesitter-highlights"] then
    return {{text}}
  else
    local opts = (_3fopts or {})
    local base_lang = (opts.lang or "fennel")
    local tmp_text
    local _20_
    if (base_lang == "fennel") then
      _20_ = text:gsub("#<(%a+):(%s+0x%x+)>", "#(%1 %2)")
    elseif (base_lang == "lua") then
      _20_ = text:gsub("<(%a+%s+%d+)>", "\"%1\"")
    else
      local _ = base_lang
      _20_ = text
    end
    tmp_text = _20_:gsub("\\", "\\\\")
    local fixed_text = text:gsub("\\", "\\\\")
    validate_type("table", opts)
    local _25_, _26_ = pcall(ts.get_string_parser, tmp_text, base_lang)
    if ((_25_ == false) and (nil ~= _26_)) then
      local msg = _26_
      local chunks = {{text}}
      vim.notify_once(msg, vim.log.levels.WARN)
      return chunks
    elseif ((_25_ == true) and (nil ~= _26_)) then
      local lang_tree = _26_
      return compose_hl_chunks(fixed_text, lang_tree)
    else
      return nil
    end
  end
end
return {["text->hl-chunks"] = text__3ehl_chunks}
