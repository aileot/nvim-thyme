(import-macros {: when-not : last} :thyme.macros)

(local {: read-file : assert-is-log-file} (require :thyme.utils.fs))

(local {: gsplit} (require :thyme.utils.iterator))

;; NOTE: lua cannot handle \0 in pattern properly.
(local marker {:sep "\t" :macro "\v" :end "\n"})

(fn modmap->line [modmap]
  "Convert `modmap` table into a line.
@param modmap table
@param modmap.module-name string
@param modmap.fnl-path string
@param modmap.lua-path string?
@return string"
  ;; NOTE: The modmap log files would not store file size, which significantly
  ;; reduces the reusability of log files in the pool.
  (assert (and modmap.module-name modmap.fnl-path)
          (: "modmap requires 'module-name' and 'fnl-path'; got module-name: %s, fnl-path: %s"
             :format modmap.module-name modmap.fnl-path))
  (.. (or modmap.lua-path marker.macro) marker.sep ;
      modmap.module-name marker.sep ;
      ;; NOTE: the log filename represents the resolved fnl path.
      modmap.fnl-path marker.end))

(fn line->modmap [line]
  "Convert `line` into a modmap table.
@return `line` string
@param table module-map"
  (let [inline-dependent-map-pattern ;
        (.. "^(.-)" marker.sep "(.-)" marker.sep "(.*)$")]
    (match (line:match inline-dependent-map-pattern)
      ;; NOTE: To tell if macro or not earlier, log macro-marker/lua-path
      ;; earlier in each line.
      (marker.macro module-name fnl-path)
      {:macro? true : module-name : fnl-path}
      (lua-path module-name fnl-path)
      {: lua-path : module-name : fnl-path}
      _
      (error (: "Invalid format: \"%s\"" :format line)))))

(fn read-module-map-file [log-path]
  "Read module-map from `log-path`.
@param log-path string
@return table"
  (collect [line (-> (read-file log-path)
                     ;; Trim the last end-marker.
                     (: :sub 1 -2)
                     (gsplit marker.end))]
    (let [{: fnl-path &as modmap} (line->modmap line)]
      (values fnl-path modmap))))

(fn macro-recorded? [log-path]
  "Tell if the primarily saved module-map in `log-path` is a macro module.
@param log-path string
@return boolean"
  (assert-is-log-file log-path)
  (with-open [file (assert (io.open log-path :r)
                           (.. "failed to read " log-path))]
    ;; Peek the first line.
    (not= nil ;
          (-> (file:read :*l)
              ;; Find macro-marker with `find` instead of comparing the line end
              ;; char with `=` just in case not to get into trouble when the log
              ;; format is updated (though unlikely): what position macro marker is
              ;; saved could be changed.
              (: :find marker.macro 1 true)))))

(fn peek-module-name [log-path]
  "Peek the primary `module-name` of the module-map recorded in `log-path`.
@param log-path string
@return string"
  (assert-is-log-file log-path)
  (with-open [file (assert (io.open log-path :r)
                           (.. "failed to read " log-path))]
    ;; Peek the first line.
    (-> (file:read :*l)
        (line->modmap)
        (. :module-name))))

(fn peek-fnl-path [log-path]
  "Peek the primary `fnl-path` of the module-map recorded in `log-path`.
@param log-path string
@return string"
  (assert-is-log-file log-path)
  (with-open [file (assert (io.open log-path :r)
                           (.. "failed to read " log-path))]
    ;; Peek the first line.
    (-> (file:read :*l)
        (line->modmap)
        (. :fnl-path))))

{: modmap->line
 : read-module-map-file
 : macro-recorded?
 : peek-module-name
 : peek-fnl-path}
