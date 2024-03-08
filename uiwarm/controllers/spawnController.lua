local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')
local abstractController = require(PATH .. "/abstractController")
local spawnController = abstractController()
local spawnService = require(ROOT .. "/services/spawnService")

local handleSpawnCommands = function(commands, a)
    local spawnedLinks = {}
    for _, spawned in pairs(commands) do
        spawnedLinks[spawned] = true
        spawnController:send("insertIntoCallbacks", spawned)
        spawnController:send("insertIntoScene", spawned)
    end

    for _, spawned in pairs(commands) do
        spawned:onCreate()
    end

    for _, spawned in pairs(commands) do
        spawnController:send("callbackHandle", { eventName = "onCreate", params = spawned })
    end
end

local spawnScene = function(data)
    local commands = spawnService:spawnScene(data.scene, data.include)
    handleSpawnCommands(commands)
end

local defineBuilder = function(configuredBuilder)
    spawnService:defineBuilder(configuredBuilder)
    local integration = spawnService:getUiApiIntegration(handleSpawnCommands)
    spawnController:send("integrateUiApi", integration)
end

local newSpawnedHandle = function(data)
    local newSpawned = spawnService:getNewSpawned()
    if #newSpawned > 0 then
        handleSpawnCommands(newSpawned)
        spawnService:clearNewSpawned()
    end
end

local defElementTypes = function(types)
    spawnService:defElementTypes(types)
end

spawnController.subscriptions["configuredBuilder"] = function(data) defineBuilder(data) end
spawnController.subscriptions["sceneSpawn"] = function(data) spawnScene(data) end
spawnController.subscriptions["elementTypesSpawn"] = function(data) defElementTypes(data) end
spawnController.subscriptions["update"] = newSpawnedHandle

return spawnController
