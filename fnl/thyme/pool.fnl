(local {: state-prefix} (require :thyme.const))

(local Path (require :thyme.utils.path))
(local fs (require :thyme.utils.fs))

(local pool-prefix (Path.join state-prefix :pool))

(vim.fn.mkdir pool-prefix :p)

(fn path->pool-path [path]
  (Path.join pool-prefix path))

(fn hide-file! [path]
  (fs.rename path (path->pool-path path)))

(fn restore-file! [path]
  (fs.rename (path->pool-path path) path))

(fn copy-file! [path]
  (fs.copyfile path (path->pool-path path)))

{: hide-file! : restore-file! : copy-file!}
