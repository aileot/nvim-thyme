(local {: state-prefix} (require :thyme.const))

(local Path (require :thyme.utils.path))
(local {: file-readable? : read-file &as fs} (require :thyme.utils.fs))

(local {: uri-encode} (require :thyme.utils.uri))
(local {: each-file} (require :thyme.utils.iterator))

(local pool-prefix (Path.join state-prefix :pool))

(vim.fn.mkdir pool-prefix :p)

(fn path->pool-path [path]
  "Determine the unique pool-path for `path`.
@param path string
@return string"
  (Path.join pool-prefix (uri-encode path)))

(fn hide-file! [path]
  "Move `path` to its own pool-path.
@param path string"
  (assert (fs.rename path (path->pool-path path))))

(fn restore-file! [path]
  "Move back `path` from its own pool-path.
@param path string"
  (-> (vim.fs.dirname path)
      (vim.fn.mkdir :p))
  (assert (fs.rename (path->pool-path path) path)))

(fn hide-files-in-dir! [dir-path]
  "Move all the files and links in the `dir-path` to their pool-paths
  respectively.
@param dir-path string"
  ;; Note: Hiding directories only add extra management costs on restoring
  ;; files later.
  (each-file hide-file! dir-path))

(fn can-restore-file? [path expected-contents]
  "Check if `expected-contents` is stored in pool-path of `path`.
@param path string
@param expected-contents string
@return boolean"
  (let [pool-path (path->pool-path path)]
    (and (file-readable? pool-path) ;
         (= (read-file pool-path)
            (assert expected-contents
                    "expected non empty string for `expected-contents`")))))

(fn get-root []
  "Return the root directory of pool.
@return string the root path"
  pool-prefix)

{: hide-file!
 : restore-file!
 : hide-files-in-dir!
 : can-restore-file?
 : get-root}
