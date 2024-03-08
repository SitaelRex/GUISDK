local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')
local abstractController = require(PATH .. "/abstractController")

local subBuilders = require(PATH .. "/subBuilders")
local include = { builder = subBuilders }

local configurationController = abstractController()


local configurationService = require(ROOT .. "/services/configurationService")

local scenes = {}


local callbackConfiguration = {}

local uiApiRef = { a = "not" }

local callbackConfigResponseHandle = function(data)
    callbackConfiguration = data
end

--TODO! разобрать бардак в этой функции
local handleConfig = function(config)
    configurationController:send("callbackConfigRequest")
    local callbacksList = {}
    for k, v in pairs(callbackConfiguration) do
        callbacksList[k] = k
    end

    config.callbacks = callbacksList
    ------------------------- чтобы не пришлось хранить билдеры в оболочке
    config.builders = subBuilders
    config.loadTypes()

    for k, v in pairs(config.funcs) do
        v()
    end

    ---------------------------
    configurationService:setBuilder(configurationService:configureBuilder(config.extensionModules, uiApiRef))
    configurationService:configureDataSources(config.dataSources)
    configurationController:send("configuredDataSources", configurationService:getConfiguredDataSources())
    configurationController:send("configuredBuilder", configurationService:getBuilder())
    configurationController:send("elementTypesSpawn", config.elementTypes)

    scenes = config.scenes
    local scene = config.scenes[config.defaultScene]

    curSceneName = config.defaultScene
    configurationController:send("sceneSpawn", { scene = scene, include = include })
end

--TODO! убрать global переменные
lastSceneName = nil
curSceneName = nil
local changeScene = function(sceneName)
    local targetSceneName = sceneName ~= "previousScene" and sceneName or lastSceneName
    local targetScene = scenes[targetSceneName]
    lastSceneName = curSceneName
    curSceneName = targetSceneName

    print(targetSceneName, curSceneName, lastSceneName)

    configurationController:send("clearScene")
    configurationController:send("sceneSpawn", { scene = targetScene, include = include }) -- targetScene)

    configurationController:send("input", { eventName = "mousemoved" })
end

local integrateUiApi = function(api)
    uiApiRef.a = api
end

configurationController.subscriptions["config"] = handleConfig
configurationController.subscriptions["callbackConfigResponse"] = callbackConfigResponseHandle
configurationController.subscriptions["changeScene"] = changeScene
configurationController.subscriptions["uiApi"] = integrateUiApi

return configurationController
