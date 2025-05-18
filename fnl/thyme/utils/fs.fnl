(import-macros {: when-not} :thyme.macros)

(local Path (require :thyme.utils.path))

(local raw-uv (or vim.uv vim.loop))

(local uv (setmetatable {}
            {:__index (fn [self key]
                        ;; Make fs_ prefix omittable.
                        (let [call (or (. raw-uv key) (. raw-uv (.. :fs_ key)))]
                          (tset self key call)
                          (fn [...]
                            (call ...))))}))

(fn executable? [cmd]
  (= 1 (vim.fn.executable cmd)))

(fn file-readable? [path]
  (and (= :string (type path)) ;
       (= 1 (vim.fn.filereadable path))))

(fn directory? [path]
  (and (= :string (type path)) ;
       (= 1 (vim.fn.isdirectory path))))

(fn assert-is-file-readable [path]
  (when-not (file-readable? path)
    (error (-> "not a readable file, got %s as type %s"
               (: :format (vim.inspect path) (type path))))))

(fn assert-is-directory [path]
  (when-not (directory? path)
    (error (-> "not a directory, got %s as type %s"
               (: :format (vim.inspect path) (type path))))))

(fn assert-is-full-path [full-path]
  (-> (if (= "/" Path.sep)
          (= "/" (full-path:sub 1 1))
          (= ":\\" (full-path:sub 2 3)))
      (assert (.. full-path " is not a full path"))))

(fn assert-file-extension [path extension]
  (assert (= "." (extension:sub 1 1)) "`extension` must start with `.`")
  (assert (= extension (path:sub (- (length extension))))
          (.. path " does not end with " extension)))

(fn assert-is-fnl-file [fnl-path]
  (assert-is-full-path fnl-path)
  (assert-file-extension fnl-path :.fnl))

(fn assert-is-lua-file [lua-path]
  (assert-is-full-path lua-path)
  (assert-file-extension lua-path :.lua))

(fn assert-is-log-file [log-path]
  (assert-is-full-path log-path)
  (assert-file-extension log-path :.log))

(fn read-file [path]
  "Read `path`.
@param path string
@return contents string"
  ;; NOTE: According to Fennel style guide, functions on IO should ends with
  ;; bang; in this project, however, affix-bang would be only for destructive
  ;; operation functions, but not for reading file with nothing to be modified
  ;; within.
  (with-open [file (assert (io.open path :r) (.. "failed to read " path))]
    (file:read :*a)))

(fn write-file! [path contents]
  "Write `contents` into `path`.
@param path string
@param contents string"
  (with-open [f (assert (io.open path :w) (.. "failed to write to " path))]
    (f:write contents)))

(fn append-file! [path contents]
  "Append `contents` into `path`.
@param path string
@param contents string"
  (with-open [f (assert (io.open path :a) (.. "failed to append to " path))]
    (f:write contents)))

(fn delete-file! [path]
  (uv.fs_unlink path))

;; WIP
;; (fn delete-directory-recursively! [dir-path]
;;   "Delete directory recursively.
;;   @param dir-path string"
;;   (assert-is-directory dir-path))

(fn write-fnl-file! [fnl-path fnl-lines]
  "Write `fnl-lines` into `fnl-path`.
@param fnl-lines string fnl code
@param fnl-path fnl path to be written"
  (assert-is-fnl-file fnl-path)
  (-> (vim.fs.dirname fnl-path)
      (vim.fn.mkdir :p))
  (write-file! fnl-path fnl-lines))

(fn write-lua-file! [lua-path lua-lines]
  "Write `lua-lines` into `lua-path`.
@param lua-lines string lua code
@param lua-path lua path to be written"
  (assert-is-lua-file lua-path)
  ;; TODO: Add verbose option.
  (-> (vim.fs.dirname lua-path)
      (vim.fn.mkdir :p))
  (write-file! lua-path lua-lines))

(fn delete-lua-file! [lua-path]
  "Delete `lua-path`.
@param lua-lines string lua code"
  (assert-is-lua-file lua-path)
  (delete-file! lua-path))

(fn delete-log-file! [log-path]
  "Delete `log-path`.
@param log-lines string log code"
  (assert-is-log-file log-path)
  (delete-file! log-path))

(fn write-log-file! [log-path log-lines]
  "Write `log-lines` into `log-path`.
@param log-lines string log code
@param log-path log path to be written"
  (assert-is-log-file log-path)
  (-> (vim.fs.dirname log-path)
      (vim.fn.mkdir :p))
  (write-file! log-path log-lines))

(fn append-log-file! [log-path log-lines]
  "Write `log-lines` into `log-path`.
@param log-lines string log code
@param log-path log path to be written"
  (assert-is-log-file log-path)
  (append-file! log-path log-lines))

(fn async-write-file-with-flags! [path text flags]
  (-> (vim.fs.dirname path)
      (vim.fn.mkdir :p))
  (let [rw- 438]
    (uv.fs_open path flags rw-
                (fn [err fd]
                  (assert (not err) err)
                  (uv.fs_write fd text
                               (fn [err]
                                 (assert (not err) err)
                                 (uv.fs_close fd
                                              (fn [err]
                                                (assert (not err) err)))))))))

(fn async-write-log-file! [log-path lines]
  (assert-is-log-file log-path)
  (async-write-file-with-flags! log-path lines :w))

(fn async-append-log-file! [log-path lines]
  (assert-is-log-file log-path)
  (async-write-file-with-flags! log-path lines :a))

(fn uv.symlink! [path new-path ...]
  "Force create symbolic link from `path` to `new-path`.
@param path string
@param new-path string
@return boolean true if symlink is successfully created, or false"
  ;; NOTE: `loop or previous error` since `utils.pool` depends on this `utils.fs` module.
  (let [{: hide-file! : has-hidden-file? : restore-file!} (require :thyme.utils.pool)]
    (when (file-readable? new-path)
      (hide-file! new-path))
    (case (pcall (assert #(vim.uv.fs_symlink path new-path)))
      (false msg) (if (has-hidden-file? new-path)
                      true
                      (do
                        (restore-file! new-path)
                        ;; NOTE: This is just a delayed error message so that
                        ;; it does not make sense to replace the `vim.notify`
                        ;; with a `Messenger.notify!`.
                        (vim.notify msg vim.log.levels.ERROR)
                        false))
      _ true)))

(setmetatable {: executable?
               : file-readable?
               : directory?
               : assert-is-file-readable
               : assert-is-directory
               : assert-is-fnl-file
               : assert-is-lua-file
               : assert-is-log-file
               : read-file
               : write-log-file!
               : append-log-file!
               : async-write-log-file!
               : async-append-log-file!
               : delete-file!
               : write-fnl-file!
               : write-lua-file!
               : delete-lua-file!
               : delete-log-file!
               : uv}
  {:__index (fn [_ key]
              (. uv key))})
