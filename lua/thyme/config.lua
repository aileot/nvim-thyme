

 local Path = require("thyme.utils.path")

 local _local_1_ = require("thyme.const") local config_filename = _local_1_["config-filename"] local config_path = _local_1_["config-path"]
 local _local_2_ = require("thyme.utils.general") local contains_3f = _local_2_["contains?"]
 local _local_3_ = require("thyme.utils.fs") local file_readable_3f = _local_3_["file-readable?"]
 local assert_is_fnl_file = _local_3_["assert-is-fnl-file"]
 local read_file = _local_3_["read-file"]
 local write_fnl_file_21 = _local_3_["write-fnl-file!"]
 local uv = _local_3_["uv"]

 local cache = {["main-config"] = nil, ["config-list"] = {}}


 local secure_config_home = (os.getenv("XDG_CONFIG_HOME") or vim.fn.expand("~/.config"))

 local secure_nvim_config_home = Path.join(secure_config_home, "nvim")
 local secure_config_path = Path.join(secure_nvim_config_home, config_filename)

 local secure_config_paths = {secure_config_path, vim.fn.resolve(secure_config_path)}



 local default_opts = {rollback = true, ["compiler-options"] = {}, ["macro-path"] = table.concat({"./fnl/?.fnl", "./fnl/?/init-macros.fnl", "./fnl/?/init.fnl"}, ";")}







 local default_opts_main_only
 local function _4_(_241) return _241 end default_opts_main_only = {preproc = _4_, notifier = {recompile = vim.notify, ["fennel-update"] = vim.notify, reload = false}}




 if not file_readable_3f(config_path) then

 local _5_ = vim.fn.confirm(("Missing \"%s\" at %s... Generate and open it?"):format(config_filename, vim.fn.stdpath("config")), "&Yes\n&no", 1, "Warning") if (_5_ == 2) then


 error("abort proceeding with nvim-thyme") else local _ = _5_ local recommended_config = ";; Generated with recommended options by nvim-thyme.\n{:rollback true\n :compiler-options {:correlate true\n                    ;; :compilerEnv _G\n                    :error-pinpoint [\"|>>\" \"<<|\"]}\n ;; The path patterns for fennel.macro-path to find Fennel macro module path.\n ;; Relative path markers (`.`) are internally replaced with the paths on\n ;; &runtimepath filtered by the directories suffixed by `?`, e.g., `fnl/` in\n ;; `./fnl/?.fnl`.\n :macro-path \"./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl\"}"












 write_fnl_file_21(config_path, recommended_config)
 vim.cmd.tabedit(config_path)
 local function _6_() if (config_path == vim.api.nvim_buf_get_name(0)) then
 local _7_ = vim.fn.confirm("Trust this file? Otherwise, it will ask your trust again on nvim restart", "&Yes\n&no", 1, "Question") if (_7_ == 2) then

 return error(("abort trusting " .. config_path)) else local _0 = _7_
 return vim.cmd.trust() end else return nil end end vim.defer_fn(_6_, 800) end else end


 local function find_config_file(path)



 local _12_ = vim.fs.find(config_filename, {upward = true, type = "file", stop = uv.os_homedir(), path = path}) if ((_G.type(_12_) == "table") and (nil ~= _12_[1])) then local project_config_path = _12_[1]

 return project_config_path else return nil end end

 local get_main_config = nil

 local function read_config(config_file_path)



 assert_is_fnl_file(config_file_path)
 local fs_stat = uv.fs_stat(config_file_path)

 local fennel = require("fennel") local config_table
 do local _14_ = cache["config-list"][config_file_path] local function _15_() local _3fcache = _14_ return ((nil == _3fcache) or (_3fcache.mtime.sec < fs_stat.mtime.sec)) end if (true and _15_()) then local _3fcache = _14_






 local secure_config_3f = contains_3f(secure_config_paths, config_file_path) local config_lines

 if secure_config_3f then
 config_lines = read_file(config_file_path) else
 config_lines = vim.secure.read(config_file_path) end
 local compiler_options = {["error-pinpoint"] = false}
 local _3fconfig = fennel.eval(config_lines, compiler_options)
 local config = (_3fconfig or {})

 local mtime = fs_stat.mtime
 cache["config-list"][config_file_path] = {config = config, mtime = mtime}

 config_table = config elseif ((_G.type(_14_) == "table") and (nil ~= _14_.config)) then local config = _14_.config

 config_table = config else config_table = nil end end
 local config = vim.tbl_deep_extend("keep", config_table, default_opts)
 return config end


 local function _18_()



 local function _19_() local main_config = vim.tbl_deep_extend("keep", read_config(config_path), default_opts_main_only)


 cache["main-config"] = main_config
 return main_config end return (cache["main-config"] or _19_()) end get_main_config = _18_

 local function config_file_3f(path)



 return (config_filename == vim.fs.basename(path)) end

 local function get_option_value(config, key) _G.assert((nil ~= key), "Missing argument key on fnl/thyme/config.fnl:126") _G.assert((nil ~= config), "Missing argument config on fnl/thyme/config.fnl:126")


 return (rawget(config, key) or rawget(default_opts, key)) end


 return {["get-main-config"] = get_main_config, ["find-config-file"] = find_config_file, ["read-config"] = read_config, ["get-option-value"] = get_option_value, ["config-file?"] = config_file_3f}
