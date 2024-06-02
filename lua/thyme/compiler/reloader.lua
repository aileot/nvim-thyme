local _local_1_ = require("thyme.utils.general")
local do_nothing = _local_1_["do-nothing"]
local function reload_module_21(module_name, _3fopts)
  local fennel = require("fennel")
  local opts = (_3fopts or {notifier = {}, ["live-reload"] = false})
  local notify_21 = (opts.notifier.reload or do_nothing)
  local live_reload_3f = (opts["live-reload"] and ((true == opts["live-reload"]) or (false ~= opts["live-reload"].enabled)))
  local _2_ = package.loaded[module_name]
  if (nil ~= _2_) then
    local mod = _2_
    package.loaded[module_name] = nil
    local _3_, _4_ = nil, nil
    local function _5_()
      return require(module_name)
    end
    _3_, _4_ = xpcall(_5_, fennel.traceback)
    if ((_3_ == true) and true) then
      local _ = _4_
      if live_reload_3f then
        return notify_21((module_name .. " has been reloaded on package.loaded"))
      else
        package.loaded[module_name] = mod
        return nil
      end
    elseif ((_3_ == false) and (nil ~= _4_)) then
      local msg = _4_
      package.loaded[module_name] = mod
      return error(msg)
    else
      return nil
    end
  elseif (_2_ == nil) then
    local _8_ = fennel["macro-loaded"][module_name]
    if (nil ~= _8_) then
      local mod = _8_
      local _let_9_ = require("thyme.searcher.macro")
      local search_fnl_macro_on_rtp = _let_9_["search-fnl-macro-on-rtp"]
      fennel["macro-loaded"][module_name] = nil
      local _10_, _11_ = nil, nil
      local function _12_()
        return search_fnl_macro_on_rtp(module_name)
      end
      _10_, _11_ = xpcall(_12_, fennel.traceback)
      if ((_10_ == true) and (nil ~= _11_)) then
        local loader = _11_
        if live_reload_3f then
          fennel["macro-loaded"][module_name] = loader(module_name)
          return notify_21((module_name .. " has been reloaded on fennel.macro-loaded"))
        else
          fennel["macro-loaded"][module_name] = mod
          return nil
        end
      elseif ((_10_ == false) and (nil ~= _11_)) then
        local msg = _11_
        fennel["macro-loaded"][module_name] = mod
        return error(msg)
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
return {["reload-module!"] = reload_module_21}
