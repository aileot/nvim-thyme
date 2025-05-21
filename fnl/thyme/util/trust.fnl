(local {: config-path} (require :thyme.const))

(local Path (require :thyme.util.path))
(local {: file-readable?} (require :thyme.util.fs))

(local M {})

(fn M.recorded? [raw-path]
  "Tell if the `raw-path` is recorded in the trust database of `vim.secure.trust`.
@param raw-path string
@return boolean if recorded, true; otherwise, false"
  (let [resolved-path raw-path
        trust-database-path (Path.join (vim.fn.stdpath :state) "trust")]
    (if (file-readable? trust-database-path)
        (let [;; NOTE: utils.fs.read-file instead returns a whole contents in
              ;; a string.
              trust-contents (vim.fn.readfile trust-database-path)]
          (accumulate [trusted? false ;
                       _ line (ipairs trust-contents) &until trusted?]
            (if (or (line:find (.. " " config-path) 1 true)
                    (line:find (.. " " resolved-path)))
                true
                false)))
        false)))

(fn M.allowed? [raw-path]
  "Tell if the `raw-path` is allowed on `vim.secure.trust`.
@param raw-path string
@return boolean if allowed, true; otherwise, false"
  (let [resolved-path raw-path
        trust-database-path (Path.join (vim.fn.stdpath :state) "trust")]
    (if (file-readable? trust-database-path)
        (let [;; NOTE: utils.fs.read-file instead returns a whole contents in
              ;; a string.
              trust-contents (vim.fn.readfile trust-database-path)
              allowed-pattern (-> "^%s+ "
                                  (: :format (string.rep "%x" 8)))]
          (accumulate [trusted? false ;
                       _ line (ipairs trust-contents) &until trusted?]
            (case (or (line:find (.. " " config-path) 1 true)
                      (line:find (.. " " resolved-path)))
              nil false
              _ (if (line:find allowed-pattern)
                    true
                    false))))
        false)))

(fn M.denied? [raw-path]
  "Tell if the `raw-path` is denied on `vim.secure.trust`.
@param raw-path string
@return boolean if denied, true; otherwise, false"
  (let [resolved-path raw-path
        trust-database-path (Path.join (vim.fn.stdpath :state) "trust")]
    (if (file-readable? trust-database-path)
        (let [trust-contents (vim.fn.readfile trust-database-path)
              denied-pattern "^! "]
          (accumulate [trusted? false ;
                       _ line (ipairs trust-contents) &until trusted?]
            (case (or (line:find (.. " " config-path) 1 true)
                      (line:find (.. " " resolved-path)))
              nil false
              _ (if (line:find denied-pattern)
                    true
                    false))))
        false)))

M
