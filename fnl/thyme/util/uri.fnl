;; NOTE: URI encoder/decoder are based on those of vim/uri.lua (RFC 2396).

(import-macros {: inc : dec} :thyme.macros)

;; NOTE: "bit" module is embedded in nvim>=0.9.0.
(local {: tohex} (require :bit))

(local Path (require :thyme.util.path))

(local appname (or vim.env.NVIM_APPNAME :nvim))
(local split-pattern (.. "/" appname "/"))

(fn encode-with-percent [char]
  (.. "%" (-> char
              (string.byte)
              (tohex 2))))

(fn uri-encode [uri]
  (let [percent-patterns "[^A-Za-z0-9%-_.!~*'()]"]
    ;; NOTE: Split at $NVIM_APPNAME part to avoid ENAMETOOLONG error.
    (case (string.find uri split-pattern 1 true)
      (_start end) (let [prefix (uri:sub 1 (dec end))
                         suffix (uri:sub (inc end))
                         prefix-encoded (prefix:gsub percent-patterns
                                                     encode-with-percent)
                         suffix-encoded (suffix:gsub percent-patterns
                                                     encode-with-percent)]
                     (Path.join prefix-encoded suffix-encoded))
      _ (error (.. "Invalid URI: " (vim.inspect uri))))))

(fn hex->char [hex]
  (-> (tonumber hex 16)
      (string.char)))

(fn uri-decode [uri]
  (case (uri:gsub "%%([a-fA-F0-9][a-fA-F0-9])" hex->char)
    decoded decoded))

{: uri-encode : uri-decode}
