(import-macros {: describe* : it*} :test.helper.busted-macros)

(include :test.helper.prerequisites)

(local Path (require :thyme.utils.path))

(local uv (or vim.uv vim.loop))
(local os-sysname (-> (uv.os_uname)
                      (. :sysname)))

(local in-windows? (-> os-sysname
                       (= :Windows_NT)))

(describe* (: "In the current platform %q," :format os-sysname)
  (if in-windows?
      (it* "the path separator `Path.sep` is determined to \"\\\""
        (assert.is_same "\\" Path.sep))
      (it* "the path separator `Path.sep` is determined to \"/\""
        (assert.is_same "/" Path.sep)))
  (describe* :Path.join
    (describe* (: "joins path components with the separator %q;" :format
                  Path.sep)
      (describe* "thus, `(Path.join :foo :bar)`"
        (let [expected-path (table.concat [:foo :bar] Path.sep)]
          (it* (: "results in %q" :format expected-path)
            (assert.is_same expected-path (Path.join :foo :bar))))))))
