local PATH = (...):gsub('%.[^%.]+$', '')

local mediator = require(PATH .. "/mediator")

local controllersList = {
    configurationController = require(PATH .. "/configurationController"),
    spawnController = require(PATH .. "/spawnController"),
    inputController = require(PATH .. "/inputController"),
    callbackController = require(PATH .. "/callbackController"),
    collisionController = require(PATH .. "/collisionController"),
    sceneController = require(PATH .. "/sceneController"),
    presentationController = require(PATH .. "/presentationController"),
    uiApiController = require(PATH .. "/uiApiController"),
}

for controllerName, controller in pairs(controllersList) do
    controller:setMediator(mediator)
    controller:configureSubscriptions()
end

local send = function(self, topic, data)
    mediator:send(topic, data)
end

local getPresentation = function(self)
    return controllersList.presentationController:getPresentation()
end

local sendData = function(self, sourceName, data)
    return controllersList.dataSourceController:sendData(sourceName, data)
end

local controllers = {}

controllers.sendData = sendData
controllers.send = send
controllers.getPresentation = getPresentation

return controllers
