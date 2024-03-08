--[[
    dependency path: io -> controllers -> services(viaServiceRegistery) -> wrappers -> core 
]]

local ui = {}
local PATH = (...):gsub('%.[^%.]+$', '')
local controllers = require(PATH .. "/controllers")
ui.load = function(self, config)
    controllers:send("init")
    controllers:send("config", config)
    controllers:send("uiApiInit")
end

ui.update = function(self)
    controllers:send("update")
    return controllers:getPresentation()
end

ui.inputEmit = function(self, eventName, params)
    controllers:send("input", { eventName = eventName, params = params })
end

ui.connectExternalLib = function(self, lib, definition, libInnerName)
    controllers:send("connectExternalLib", { lib = lib, definition = definition, libInnerName = libInnerName })
end

ui.getPresentation = function(self)
    local presentationResponse = {}
    return presentationResponse
end

return ui
