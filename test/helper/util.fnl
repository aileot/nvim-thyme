(local Path (require :thyme.util.path))
(local {: write-fnl-file! : write-lua-file!} (require :thyme.util.fs))
(local Config (require :thyme.config))

(local context-root vim.env.XDG_DATA_HOME)

(local test-context-root (Path.join context-root "test"))

;; NOTE: Both nvim_input and nvim_feedkeys do not seem to throw errors.

(λ vim/normal [str]
  (let [keys (vim.keycode str)]
    (vim.cmd (.. "normal " keys))))

(λ vim/normal! [str]
  (let [keys (vim.keycode str)]
    (vim.cmd (.. "normal! " keys))))

(λ prepare-config-fnl-file! [filename contents]
  "Prepare a fnl file in `Config.fnl-dir` under the test context .config/ for testing.
@param filename string
@param contents string
@return string the full path to the generated file"
  (assert (not= "/" (filename:sub 1 1))
          (.. "expected a filename, got fullpath " filename))
  (assert (filename:find "%.[a-z]+$")
          (.. "expected a filename with extension, got " filename))
  (assert (= :string (type contents))
          (-> "expected string, got %s: %s "
              (: :format (type contents) (vim.inspect contents))))
  (let [path (Path.join (vim.fn.stdpath :config) Config.fnl-dir filename)]
    (write-fnl-file! path contents)
    path))

(λ prepare-config-lua-file! [filename contents]
  "Prepare a lua file in `lua` under the test context .config/ for testing.
@param filename string
@param contents string
@return string the full path to the generated file"
  (assert (not= "/" (filename:sub 1 1))
          (.. "expected a filename, got fullpath " filename))
  (assert (filename:find "%.[a-z]+$")
          (.. "expected a filename with extension, got " filename))
  (assert (= :string (type contents))
          (-> "expected string, got %s: %s "
              (: :format (type contents) (vim.inspect contents))))
  (let [path (Path.join (vim.fn.stdpath :config) "lua" filename)]
    (write-lua-file! path contents)
    path))

(fn prepare-context-fnl-file! [filename contents]
  "Prepare a fnl file for testing. Return the full path to the context file.
@param filename string
@param contents string
@return string"
  (assert (not= "/" (filename:sub 1 1))
          (.. "expected a filename, got fullpath " filename))
  (assert (= :string (type contents))
          (-> "expected string, got %s: %s "
              (: :format (type contents) (vim.inspect contents))))
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
  (vim.cmd "% bdelete!")
  (vim.fn.delete test-context-root :rf)
  (let [cache-dirs [:cache :data :state]]
    (each [_ dir (ipairs cache-dirs)]
      (-> (vim.fn.stdpath dir)
          (vim.fs.joinpath :thyme)
          (vim.fn.delete :rf)))))

{: vim/normal
 : vim/normal!
 : prepare-config-fnl-file!
 : prepare-config-lua-file!
 : prepare-context-fnl-file!
 : prepare-context-lua-file!
 : remove-context-files!}
