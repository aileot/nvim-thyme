;; Note: URI encoder/decoder are based on those of vim/uri.lua (RFC 2396).

;; Note: "bit" module is embedded in nvim>=0.9.0.
(local {: tohex} (require :bit))

(fn encode-with-percent [char]
  (.. "%" (-> char
              (string.byte)
              (tohex 2))))

(fn uri-encode [uri]
  (let [percent-patterns "[^A-Za-z0-9%-_.!~*'()]"]
    (uri:gsub percent-patterns encode-with-percent)))

(fn hex->char [hex]
  (-> (tonumber hex 16)
      (string.char)))

(fn uri-decode [uri]
  (uri:gsub "%%([a-fA-F0-9][a-fA-F0-9])" hex->char))

{: uri-encode : uri-decode}
