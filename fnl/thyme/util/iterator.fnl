(import-macros {: when-not : inc : dec} :thyme.macros)

(local Path (require :thyme.util.path))

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
  (each [relative-path fs-type (vim.fs.dir dir-path {:depth math.huge})]
    (let [full-path (Path.join dir-path relative-path)]
      (case fs-type
        :file (call full-path)
        :directory (each-file call full-path)
        :link (call full-path)
        else (error (.. "expected :file or :directory, got " else))))))

(fn each-dir [call dir-path]
  "Iterate over directories, from children to parent, and execute `call`."
  (each [relative-path fs-type (vim.fs.dir dir-path {:depth math.huge})]
    (let [full-path (Path.join dir-path relative-path)]
      (when (= fs-type :directory)
        (each-dir call full-path)
        (call full-path)))))

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
 : each-dir
 : walk-tree}
