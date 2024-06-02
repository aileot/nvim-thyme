(import-macros {: when-not : last} :thyme.macros)

(local {: read-file} (require :thyme.utils.fs))

(local {: gsplit} (require :thyme.utils.iterator))

;; Note: lua cannot handle \0 in pattern properly.
(local marker {:sep "\t" :macro "\v" :end "\n"})

(fn modmap->line [modmap]
  "Convert `modmap` table into a line.
@param modmap table
@param modmap.fnl-path string
@param modmap.module-name string
@param modmap.lua-path string?
@return string"
  (assert (and modmap.module-name modmap.fnl-path)
          (: "modmap requires 'module-name' and 'fnl-path'; got module-name: %s, fnl-path: %s"
             :format modmap.module-name modmap.fnl-path))
  (.. modmap.module-name marker.sep ;
      ;; Note: the log filename represents the resolved fnl path.
      modmap.fnl-path marker.sep ;
      (or modmap.lua-path marker.macro) ;
      marker.end))

(fn line->modmap [line]
  "Convert `line` into a modmap table.
@return `line` string
@param table"
  (let [inline-dependent-map-pattern ;
        (.. "^(.-)" marker.sep "(.-)" marker.sep "(.*)$")]
    (case (line:match inline-dependent-map-pattern)
      (module-name fnl-path lua-path) (match lua-path
                                        (marker.macro) {: module-name
                                                        : fnl-path
                                                        :macro? true}
                                        _ {: module-name : fnl-path : lua-path})
      _ (error (: "Invalid format: \"%s\"" ;
                  :format line)))))

(fn read-module-map-file [log-path]
  "Get a dependent-map of `dependency-fnl-path`.
The map is restored from the corresponding cache file, or is initialized by an
empty table.
@param self table
@param dependency-fnl-path string
@return table"
  (collect [line (-> (read-file log-path)
                     ;; Trim the last end-marker.
                     (: :sub 1 -2)
                     (gsplit marker.end))]
    (let [{: fnl-path &as modmap} (line->modmap line)]
      (values fnl-path modmap))))

{: modmap->line : read-module-map-file}
