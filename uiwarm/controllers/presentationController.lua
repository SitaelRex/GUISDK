local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')
local abstractController = require(PATH .. "/abstractController")
local presentationController = abstractController()
local presentationService = require(ROOT .. "/services/presentationService")

local updatePresentation = function(scene)
    presentationService:updatePresentation(scene)
    presentationController:send("nextFrameCallbacks", presentationService:getNextFrameCallbacks())
end

local getPresentation = function(self)
    return presentationService:getPresentation()
end

presentationController.getPresentation = getPresentation

presentationController.subscriptions["presentationUpdate"] = function(data) updatePresentation(data) end
presentationController.subscriptions["uiApi"] = presentationService.handleUiApi
return presentationController
