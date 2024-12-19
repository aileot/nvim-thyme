(local Path (require :thyme.utils.path))
(local {: write-fnl-file! : write-lua-file!} (require :thyme.utils.fs))

(local context-root vim.env.XDG_DATA_HOME)

(local test-context-root (Path.join context-root "test"))

(fn prepare-context-fnl-file! [filename contents]
  "Prepare a fnl file for testing. Return the full path to the context file.
@param filename string
@param contents string
@return string"
  (assert (not= "/" (filename:sub 1 1))
          (.. "expected a filename, got fullpath " filename))
  (let [path (Path.join test-context-root filename)]
    (write-fnl-file! path contents)
    path))

(fn prepare-context-lua-file! [filename contents]
  "Prepare a lua file for testing. Return the full path to the context file.
@param filename string
@param contents string
@return string"
  (assert (not= "/" (filename:sub 1 1))
          (.. "expected a filename, got fullpath " filename))
  (let [path (Path.join test-context-root filename)]
    (write-lua-file! path contents)
    path))

(fn remove-context-files! []
  (pcall vim.fn.delete test-context-root :rf))

{: prepare-context-fnl-file!
 : prepare-context-lua-file!
 : remove-context-files!}
