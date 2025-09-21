local Config = require("thyme.config")
local M = {}
M["enable-dropin-paren!"] = function()
  if Config.integration.dropin then
    local dropin = require("dropin")
    dropin.pattern("^(.-)[fF][nN][lL]?(.*)", "%1Fnl%2")
    return dropin.pattern("^(.-)([[%[%(%{].*)", "%1Fnl %2")
  else
    return nil
  end
end
return M
