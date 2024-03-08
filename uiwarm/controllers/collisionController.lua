local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')
local abstractController = require(PATH .. "/abstractController")

local collisionController = abstractController()

local collisionService = require(ROOT .. "/services/collisionService")

local sendHover = function()
    collisionController:send("updateHover", collisionService:getCollision())
end

local collisionUpdate = function(data)
    collisionService:collisionUpdate({ x = data.params.x, y = data.params.y })
    sendHover()
end

local sceneStateUpdate = function(data)
    collisionService:sceneStateUpdate(data)
end

collisionController.subscriptions["collisionUpdate"] = collisionUpdate
collisionController.subscriptions["sceneStateUpdate"] = sceneStateUpdate
return collisionController
