(import-macros {: when-not : inc : dec} :thyme.macros)

(fn ipairs-reverse [seq]
  "`ipairs` but in reverse order.
@param seq sequence
@return fun(): any"
  (let [max-idx (length seq)]
    (var i 0)
    (var idx max-idx)
    (fn []
      (let [val (. seq idx)]
        (set i (+ i 1))
        (set idx (- idx 1))
        (when (< 0 idx)
          (values i val))))))

(fn char-by-char [str]
  (let [max-idx (length str)]
    (var i 0)
    #(when (< i max-idx)
       (set i (inc i))
       (let [char (str:sub i i)]
         (values i char)))))

(fn uncouple-substrings [str delimiter]
  "Iterate substrings cut off at `delimiter` from `str`, e.g., given a string
\"foo.bar.baz\" with delimiter \".\", it returns \"foo.bar.baz\", \"foo.bar\",
and then \"foo\".
@param str string
@param delimiter string
@return fun(): string"
  (var result nil)
  (var rest str)
  (let [reversed-str (str:reverse)]
    (fn []
      (when-not (= "" rest)
        (set result rest)
        (case (reversed-str:find delimiter 1 true)
          idx (do
                (set rest (str:sub 1 (- -1 idx)))))
        result))))

(fn gsplit [str sep]
  "Iterate substrings in `str` split at `sep`. Unlike vim.gsplit, this
iterator is only for plain text.
@param str string
@param sep string
@return fun(): string?"
  (var idx-from nil)
  (var ?idx-sep-start 0)
  (var ?idx-sep-end 0)
  (fn []
    ;; string.find returns `nil` at the end.
    (when ?idx-sep-end
      (set idx-from (inc ?idx-sep-end))
      (set (?idx-sep-start ?idx-sep-end) (str:find sep (inc idx-from) true))
      (let [?idx-to (when ?idx-sep-start
                      (dec ?idx-sep-start))]
        (str:sub idx-from ?idx-to)))))

(fn pairs-from-longer-key [tbl]
  "Iterate `tbl` from longer named key to shorter one.
@param tbl table
@return fun(): any"
  (let [keys (icollect [k _ (pairs tbl)]
               k)]
    (table.sort keys (fn [a b]
                       (< (length b) (length a))))
    (var i 0)
    (fn []
      (set i (inc i))
      (let [key (. keys i)]
        (values key (. tbl key))))))

(fn each-file [call dir-path]
  "Iterate over files and execute `call`. Directories are ignored."
  (each [path fs-type (vim.fs.dir dir-path {:depth math.huge})]
    (case fs-type
      :file (call path)
      :directory (each-file call path)
      else (error (.. "expected :file or :directory, got " else)))))

(fn double-quoted-or-else [text]
  "Split `text` at `double-quoted string` or anything else. Use it like
`string.gmatch`.
@param text
@return fun(): string?"
  (let [pat-double-quoted "^\".-[^\\]\""
        pat-empty-string "^\"\""
        pat-else "^[^\"]+"
        patterns [pat-double-quoted pat-empty-string pat-else]
        max-idx (length patterns)]
    (var rest text)
    (fn []
      (accumulate [result nil ;
                   i pat (ipairs patterns) &until result]
        (case (rest:find pat)
          (idx-from idx-to) (let [result (rest:sub idx-from idx-to)]
                              (set rest (rest:sub (+ 1 idx-to)))
                              result)
          _ (when (and (= i max-idx) (not= "" rest))
              (error (: "expected empty string, failed to consume the rest of the string.
- Consumed text:
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%s
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
- The rest:
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%s
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                        :format (text:sub 1 (- 1 (length rest))) ;
                        rest))))))))

(fn string-or-else [text]
  "Split `text` at `string` or non-string text. Use it like `string.gmatch`.
@param text
@return fun(): string?"
  ;; Note: `\"` only matters inside double-quoted string.
  (let [pat-string "^\".-[^\\]\""
        pat-empty-string "^\"\""
        pat-spaces "^[%s\n]+"
        pat-colon-string "^:[^%])}%s\n]+"
        pat-non-string "^[^\"]+"
        patterns [pat-spaces
                  pat-string
                  pat-empty-string
                  pat-colon-string
                  pat-non-string]
        max-idx (length patterns)]
    (var rest text)
    (var last-pat nil)
    (var last-matched nil)
    (fn []
      ;; Note: `or` list does not let us construct `string.find` failback
      ;; sequence.
      (accumulate [result nil ;
                   i pat (ipairs patterns) &until result]
        (case (rest:find pat)
          (idx-from idx-to) (let [result (rest:sub idx-from idx-to)]
                              (set last-pat pat)
                              (set last-matched result)
                              (set rest (rest:sub (+ 1 idx-to)))
                              result)
          _ (when (and (= i max-idx) (not= "" rest))
              (error (: "expected empty string, failed to consume the rest of the string.
- Consumed text:
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%s
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

The last matched pattern: %s

The last matched string:
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%s
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

- The rest:
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%s
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                        :format (text:sub 1 (- 1 (length rest))) ;
                        last-pat last-matched rest))))))))

;; Copiled from src/fennel/utils.fnl @318
(fn walk-tree [root f ?custom-iterator]
  "Walks a tree (like the AST), invoking f(node, idx, parent) on each node.
When f returns a truthy value, recursively walks the children."
  (fn walk [iterfn parent idx node]
    (when (f idx node parent)
      (each [k v (iterfn node)]
        (walk iterfn node k v))))

  (walk (or ?custom-iterator pairs) nil nil root)
  root)

{: ipairs-reverse
 : char-by-char
 : uncouple-substrings
 : gsplit
 : pairs-from-longer-key
 : each-file
 : double-quoted-or-else
 : string-or-else
 : walk-tree}
