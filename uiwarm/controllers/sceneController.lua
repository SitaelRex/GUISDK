local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')
local abstractController = require(PATH .. "/abstractController")
local sceneController = abstractController()
local sceneService = require(ROOT .. "/services/sceneService")

local destroyCallabackInvoker = function(element)
    sceneController:send("callbackHandle", { eventName = "onDestroy", params = element })
end

local attachCallbackInvoker = function(element)
    sceneController:send("callbackHandle", { eventName = "onAttach", params = element })
end

local callbackInvokers = {
    onDestroy = destroyCallabackInvoker,
    onAttach = attachCallbackInvoker
}

local init = function()
    sceneService:setCallbackInvokers(callbackInvokers)
end

local sceneUpdateState = function()
    --для обновления стейта в collision контроллере
    sceneController:send("sceneStateUpdate", sceneService:getScene())
end

local insertToScene = function(spawned)
    sceneService:insertToScene(spawned)
    sceneUpdateState()
end

local update = function()
    local detached = sceneService:getNewDetached()
    for k, v in pairs(detached) do
        sceneController:send("callbackHandle", { eventName = "onDetach", params = v })
        table.remove(detached, 1)
    end

    local attached = sceneService:getNewAttached()
    for k, v in pairs(attached) do
        sceneController:send("callbackHandle", { eventName = "onAttach", params = v })
        table.remove(attached, 1)
    end

    local moved = sceneService:getNewMoved()
    for k, v in pairs(moved) do
        sceneController:send("callbackHandle", { eventName = "onMove", params = v })
        table.remove(moved, 1)
    end

    local resized = sceneService:getNewResized()
    for k, v in pairs(resized) do
        sceneController:send("callbackHandle", { eventName = "onResize", params = v })
        table.remove(resized, 1)
    end

    sceneController:send("presentationUpdate", sceneService:getScene())
    sceneUpdateState()
end

local clearScene = function()
    sceneService:clearScene()
end

sceneController.subscriptions["insertIntoScene"] = function(data) insertToScene(data) end
sceneController.subscriptions["update"] = update
sceneController.subscriptions["init"] = init
sceneController.subscriptions["clearScene"] = clearScene

return sceneController
