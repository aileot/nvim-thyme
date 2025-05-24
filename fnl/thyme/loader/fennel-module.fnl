(import-macros {: when-not : last : nvim-get-option} :thyme.macros)

(local {: lua-cache-prefix} (require :thyme.const))

(local Path (require :thyme.util.path))

(local {: executable? : assert-is-file-readable : read-file &as fs}
       (require :thyme.util.fs))

(local {: can-restore-file? : restore-file!} (require :thyme.util.pool))

(fn compile-fennel-into-rtp! [fennel-repo-path]
  "Compile src/fennel.fnl into lua/ at nvim-thyme cache dir, and return the
fennel.lua.
@param fennel-repo-path string the path to a fennel repository
@return function a lua chunk of fennel.lua."
  (let [fennel-lua-file "fennel.lua"
        [fennel-src-Makefile] (vim.fs.find "Makefile"
                                           {:upward true
                                            :path fennel-repo-path})
        _ (assert fennel-src-Makefile "Could not find Makefile for fennel.lua.")
        fennel-src-root (vim.fs.dirname fennel-src-Makefile)
        ?lua (if (executable? :luajit) "luajit" (executable? :lua)
                 (let [stdout (-> (vim.system [:lua :-v] {:text true})
                                  (: :wait)
                                  (. :stdout))]
                   ;; NOTE: The `lua` should be lua5.1 or luajit.
                   (when (or (stdout:find "^LuaJIT")
                             (stdout:find "^Lua 5%.1%."))
                     "lua")))
        LUA (or ?lua "nvim --clean --headless -l")
        env {: LUA}
        on-exit (fn [out]
                  (assert (= 0 (tonumber out.code))
                          (-> "failed to compile fennel.lua with code: %s\n%s"
                              (: :format out.code out.stderr))))
        make-cmd [:make :-C fennel-src-root fennel-lua-file]
        fennel-lua-path (Path.join fennel-src-root fennel-lua-file)]
    (-> (vim.system make-cmd {:text true : env} on-exit)
        (: :wait))
    (values fennel-lua-path)))

(fn locate-fennel-path! []
  "Find a fennel module on `&rtp`; otherwise, try to load the executable.
@return string a fennel.lua path"
  (or (case (vim.api.nvim_get_runtime_file :fennel.lua false)
        [fennel-lua-path] fennel-lua-path
        [nil] false) ;
      (case (vim.api.nvim_get_runtime_file :fennel false)
        [fennel-lua-path] fennel-lua-path
        [nil] false) ;
      (let [rtp (nvim-get-option :rtp)]
        (case (or (rtp:match (Path.join "([^,]+" "fennel),"))
                  (rtp:match (Path.join "([^,]+" "fennel)$")))
          fennel-repo-path (compile-fennel-into-rtp! fennel-repo-path)
          _ (if (executable? :fennel)
                ;; NOTE: The uv version vim.uv.exepath only returns the `nvim`
                ;; executable path instead of `fennel`.
                (vim.fn.exepath :fennel)
                ;; TODO: Update the missing fennel error message.
                (error "please make sure to add the path to fennel repo in `&runtimepath`"))))))

(fn cache-fennel-lua! [fennel-lua-path]
  "Cache fennel.lua into nvim-thyme cache dir.
@param fennel-lua-path string the original fennel.lua path
@return string the fennel.lua path cached by nvim-thyme"
  (assert-is-file-readable fennel-lua-path)
  (let [fennel-lua-file "fennel.lua"
        cached-fennel-path (Path.join lua-cache-prefix fennel-lua-file)]
    (when-not (= cached-fennel-path fennel-lua-path)
      (-> (vim.fs.dirname cached-fennel-path)
          (vim.fn.mkdir :p))
      (if (can-restore-file? cached-fennel-path (read-file fennel-lua-path))
          (restore-file! cached-fennel-path)
          (fs.copyfile fennel-lua-path cached-fennel-path))
      (assert-is-file-readable cached-fennel-path))
    cached-fennel-path))

(fn load-fennel [fennel-lua-path]
  ;; NOTE: It must return Lua expression, i.e., read-file is unsuitable.
  ;; NOTE: Evaluating fennel.lua by (require :fennel) is unsuitable;
  ;; otherwise, it gets into infinite loop since this function runs as
  ;; a loader of `require`.
  (let [cached-fennel-path (cache-fennel-lua! fennel-lua-path)]
    (assert (loadfile cached-fennel-path))))

{: locate-fennel-path! : load-fennel}
