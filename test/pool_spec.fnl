(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local {: path->pool-path} (require :thyme.util.pool))

(describe* "path->pool-path"
  (it* "keeps a readable slice of `path` so it can be found with a filename filter"
    (let [name (vim.fs.basename (path->pool-path "/path/to/foo.fnl"))]
      (assert.is_not_nil (string.find name "foo.fnl" 1 true))))
  (it* "treats an already-encoded `path` as opaque"
    (let [name (vim.fs.basename (path->pool-path "/a/%2fmodmap%2ffoo.fnl.log"))]
      (assert.is_not_nil (string.find name "%2f" 1 true))
      (assert.is_nil (string.find name "/" 1 true))))
  (it* "stays unique even when the readable parts are the same"
    (let [prefix-a (string.rep "x/" 200)
          prefix-b (string.rep "y/" 200)]
      (assert.is_not_same (path->pool-path (.. "/" prefix-a "shared/foo.fnl"))
                          (path->pool-path (.. "/" prefix-b "shared/foo.fnl")))))
  (it* "stays within NAME_MAX for deep paths"
    (let [deep (.. "/" (string.rep "long/" 100) "foo.fnl")
          name (vim.fs.basename (path->pool-path deep))]
      (assert.is_true (< (length name) 255)))))
