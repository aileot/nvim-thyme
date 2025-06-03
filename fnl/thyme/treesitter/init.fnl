(local {: text->hl-chunks} (require :thyme.treesitter.chunks))

(λ echo [text ?opts]
  "Echo `text` with treesitter highlights.
The result does not affect message history as `:echo` does not either."
  (let [hl-chunks (text->hl-chunks text ?opts)]
    (vim.api.nvim_echo hl-chunks false {})))

(λ print [text ?opts]
  "Print `text` with treesitter highlights.
It adds the result message to message history as `vim.print` does."
  (let [hl-chunks (text->hl-chunks text ?opts)]
    (vim.api.nvim_echo hl-chunks true {})))

{: echo : print}
