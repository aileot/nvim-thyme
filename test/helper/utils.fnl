(local Path (require :thyme.utils.path))
(local {: write-fnl-file! : write-lua-file!} (require :thyme.utils.fs))

(local context-root vim.env.XDG_DATA_HOME)

(local test-context-root (Path.join context-root "test"))

(fn prepare-config-fnl-file! [filename contents]
  "Prepare a fnl file under test context .config/ for testing. Return the full
path to the prepared file.
@param filename string
@param contents string
@return string"
  (assert (not= "/" (filename:sub 1 1))
          (.. "expected a filename, got fullpath " filename))
  (let [path (Path.join (vim.fn.stdpath :config) :fnl filename)]
    (write-fnl-file! path contents)
    path))

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
  ;; NOTE: Indiscriminately removing stdpath/data results in too many attempts
  ;; to re-download the online test deps like fennel, parinfer, etc.
  (let [cache-dirs [:cache :data :state]]
    (each [_ dir (ipairs cache-dirs)]
      (-> (vim.fn.stdpath dir)
          (vim.fs.joinpath :thyme)
          (vim.fn.delete :rf)))))

{: prepare-config-fnl-file!
 : prepare-context-fnl-file!
 : prepare-context-lua-file!
 : remove-context-files!}
