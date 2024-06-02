(local {: state-prefix} (require :thyme.const))

(local Path (require :thyme.utils.path))
(local fs (require :thyme.utils.fs))

(local {: uri-encode} (require :thyme.utils.uri))
(local {: each-file} (require :thyme.utils.iterator))

(local pool-prefix (Path.join state-prefix :pool))

(vim.fn.mkdir pool-prefix :p)

(fn path->pool-path [path]
  (Path.join pool-prefix (uri-encode path)))

(fn hide-file! [path]
  (fs.rename path (path->pool-path path)))

(fn restore-file! [path]
  (fs.rename (path->pool-path path) path))

(fn copy-file! [path]
  (fs.copyfile path (path->pool-path path)))

(fn hide-dir! [dir-path]
  (each-file hide-file! dir-path))

{: hide-file! : restore-file! : copy-file! : hide-dir!}
