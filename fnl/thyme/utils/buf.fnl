(import-macros {: tbl? : inc : dec : first : second : nvim} :thyme.macros)

(fn buf-get-text-in-range [buf start end]
  "Get text of `buf` from `start` to `end`. Both `start` and `end` can be
either number (via vim.api.nvim_buf_get_lines) or numbers[]
(via vim.api.nvim_buf_get_text), but their indices are expected in the format
of vim.api.nvim_buf_get_mark.
@param buf number
@param start number|number[]
@param end number|number[]
@return string"
  (-> (case (values start end)
        ([row1 col01] [row2 col02])
        (vim.api.nvim_buf_get_text buf (dec row1) col01 (dec row2) (inc col02)
                                   {})
        (row1 row2) (vim.api.nvim_buf_get_lines buf (dec row1) row2 true))
      (table.concat "\n")))

(fn buf-marks->text [...]
  "Extract `text` within given marks from a buffer.
@param buf number? if omitted, current buffer is the target
@param mark1 string
@param mark2 string
@return string"
  (let [(buf mark1 mark2) (case (select "#" ...)
                            2 (values 0 ...)
                            3 ...
                            _ (error (.. "expected 2 or 3 args, got "
                                         (table.concat [...] ","))))
        (start end) (case (values (vim.api.nvim_buf_get_mark buf mark1)
                                  (vim.api.nvim_buf_get_mark buf mark2))
                      ([row1 &as start] [row2 &as end]) (if (<= row1 row2)
                                                            (values start end)
                                                            (values end start)))
        end-row (first end)
        ;; Note: vim.fn.getregtype only get updated in Operator-pending mode:
        ;; it does not always make sense in Visual mode. This line length
        ;; comparison at the end-row is a workaround to tell if this function
        ;; is called in Visual mode or not.
        [end-line] (vim.api.nvim_buf_get_lines buf (dec end-row) end-row true)
        end-col (length end-line)
        linewise? (< end-col (second end))
        text (if linewise?
                 (buf-get-text-in-range 0 (first start) (first end))
                 (buf-get-text-in-range 0 start end))]
    text))

{: buf-get-text-in-range : buf-marks->text}
