local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')

local uiElement = require(ROOT .. "/wrappers/uiElement")
local builder
local elementTypes = {}
local spawnService = {}

local spawn = function(elementTable, subBuilders)
    local builderFactory = function()
        return builder(uiElement)
    end

    local results = elementTable(builderFactory, subBuilders):complete()
    return results
end

local spawnScene = function(self, data, include)
    local scene = data
    local spawned = {}
    for index, elementTable in pairs(scene.elements) do
        local spawnResult = spawn(elementTable, include)
        for i = 1, #spawnResult do
            spawned[#spawned + 1] = spawnResult[i]
        end
    end
    return spawned
end

local newSpawned = {}

local getNewSpawned = function(self)
    return newSpawned
end

local clearNewSpawned = function(self)
    newSpawned = {}
end

local handleIntegration = function()
    local uiApiIntegration = {}

    for k, v in pairs(uiElement.integrateApiUI) do
        uiApiIntegration[k] = v
    end

    uiApiIntegration.detach = function(self, targetName)
        local target = self:getByIdentity(targetName)
        if target then
            target:detach()
        end
    end

    uiApiIntegration.attach = function(self, currentName, targetName)
        local current = self:getByIdentity(currentName)
        local target = self:getByIdentity(targetName)
        current:detach()
        target:attach(current)
    end

    uiApiIntegration.spawn = function(self, elementTable, targetName)
        local results = spawn(elementTable)
        local spawned = {}
        for i = 1, #results do
            spawned[#spawned + 1] = results[i]
        end

        local target = self:getByIdentity(targetName)
        if target then
            spawned[1].parent = target
        end

        if #newSpawned == 0 then
            newSpawned = spawned
        else --"insert newspawned"
            for k, v in pairs(spawned) do
                table.insert(newSpawned, v)
            end
        end
    end

    return uiApiIntegration
end

local getUiApiIntegration = function(self)
    return handleIntegration()
end

local defineBuilder = function(self, configuredBuilder)
    builder = configuredBuilder
end

local defElementTypes = function(self, types)
    for typeName, typeIncompletedBuilder in pairs(types) do
        elementTypes[typeName] = typeIncompletedBuilder
    end
end

spawnService.defineBuilder = defineBuilder
spawnService.spawnScene = spawnScene
spawnService.defElementTypes = defElementTypes
spawnService.getUiApiIntegration = getUiApiIntegration
spawnService.getNewSpawned = getNewSpawned
spawnService.clearNewSpawned = clearNewSpawned

return spawnService
