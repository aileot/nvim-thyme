(import-macros {: describe* : it*} :test.helper.busted-macros)

(local {: uri-encode : uri-decode} (require :thyme.util.uri))

(describe* "uri-encode"
  (it* "encodes /path/to/nvim/fnl/foo.fnl leaving a `/` in the result."
    (var count 0)
    (each [_ (-> (uri-encode "/path/to/nvim/fnl/foo.fnl")
                 (string.gmatch "/"))]
      (set count (+ 1 count)))
    (assert.equals 1 count)))

(describe* "uri-decode"
  (it* "restores encoded path to the original path before being encoded."
    (let [original-path "path/to/nvim/fnl/foo.fnl"]
      (-> original-path
          (uri-encode)
          (uri-decode)
          (assert.equals original-path)))))
