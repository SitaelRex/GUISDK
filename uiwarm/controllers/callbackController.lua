local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')
local abstractController = require(PATH .. "/abstractController")

local callbackController = abstractController()

local callbackService = require(ROOT .. "/services/callbackService")

local configRequestHandle = function()
    local config = callbackService:getCallbackConfig()
    callbackController:send("callbackConfigResponse", config)
end

local updateHoverFocus = function(data)
    callbackService:updateHoverFocus(data)
end

callbackController.subscriptions["callbackConfigRequest"] = configRequestHandle
callbackController.subscriptions["updateHoverFocus"] = updateHoverFocus
callbackController.subscriptions["nextFrameCallbacks"] = callbackService.setCallbacks
callbackController.subscriptions["uiApi"] = callbackService.handleUiApi
callbackController.subscriptions["callbackHandle"] = callbackService.handleCallback
callbackController.subscriptions["insertIntoCallbacks"] = callbackService.listenElement
callbackController.subscriptions["removeFromCallbacks"] = callbackService.removeFromListen
callbackController.subscriptions["updateHover"] = function(data)
    callbackService.updateHover(data)
    callbackController:send("uiApiOverlapped", callbackService.getOverlapped())
end

return callbackController
