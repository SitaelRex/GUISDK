local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')
local abstractController = require(PATH .. "/abstractController")
local uiApiController = abstractController()
local uiApiService = require(ROOT .. "/services/inputService")
local inputCords = { x = 0, y = 0 }
local overlapped = nil
local uiApi = {}

local integrateUiApi = function(data)
    for k, v in pairs(data) do
        uiApi[k] = v
    end
end

local initApi = function()
    uiApiController:send("uiApi", uiApi)
end

local setInputCords = function(data)
    inputCords.x = data.x
    inputCords.y = data.y
end

local setOverlapped = function(data)
    overlapped = data
end

uiApi.getInputCords = function(self)
    return inputCords
end

uiApi.getOverlapped = function(self)
    return overlapped
end

uiApi.setHoverFocus = function(self, element, triggeredBy)
    uiApiController:send("updateHoverFocus", { element = element, trigger = triggeredBy })
end

uiApi.changeScene = function(self, sceneName)
    uiApiController:send("changeScene", sceneName)
end

uiApi.previousScene = function(self)
    uiApiController:send("changeScene", "previousScene")
end

local dataSourceDefinitions = {}
local dataSources = {}

local testParamMapper = function(index)
    return index * 2
end

local testOperationMapper = function(response)
    reponse.mapped = true
    return response
end

--TODO! перенести всё связанное с dataSource в отдельный контроллер и сервис
local dataSourceBuilder = function()
    local builderInstance = {}
    builderInstance.result = {}
    builderInstance.result.operations = {}
    local emptyContext = "NONE"
    builderInstance.operationContext = emptyContext

    builderInstance.addOperation = function(self, nameAs, libName)
        builderInstance.operationContext = nameAs
        result.operations[nameAs] = { funcName = libName, params = {}, operationMapper = nil }
        return self
    end

    builderInstance.addMapper = function(self, paramIndex, mapperFunc)
        if builderInstance.operationContext ~= emptyContext then
            result.operations[builderInstance.operationContext][paramIndex] = mapperFunc
        else
            print("builderInstance.addMapper EMPTY OPERATION CONTEXT")
        end

        return self
    end

    builderInstance.addOperationMapper = function(self, mapperFunc)
        if builderInstance.operationContext ~= emptyContext then
            result.operations[builderInstance.operationContext].operationMapper = mapperFunc
        else
            print("builderInstance.addMapper EMPTY OPERATION CONTEXT")
        end
        return self
    end

    builderInstance.complete = function(self)
        builderInstance.operationContext = emptyContext
        return self.result
    end

    return builderInstance
end

local dataSourceProxyFactory = function(dataSourceTemplate)
    local dataSourceProxy = {}
    local operations = dataSourceTemplate.operations
    dataSourceProxy.connectedLibs = {}
    dataSourceProxy.connect = function(self, lib, libInnerName)
        local dataSource = {}
        self.connectedLibs[# self.connectedLibs + 1] = libInnerName
        for funcName, description in pairs(operations) do
            local libFunc = lib[description.funcName]
            local params = lib[description.params]
            local proxyField = {}
            proxyField.description = description

            setmetatable(proxyField, {
                __call = function(self, ...)
                    local arguments = { ... }
                    local mappedArgs = {}
                    local operation = operations[funcName]
                    local params = operation.params
                    for argKey, argValue in pairs(arguments) do
                        local value = argValue
                        if operation.params[argKey] then
                            value = params[argKey](value)
                        end
                        mappedArgs[argKey] = value
                    end
                    local response = { libFunc(unpack(mappedArgs)) }
                    return operation.operationMapper and operation.operationMapper(unpack(response)) or unpack(response)
                end
            })
            dataSource[funcName] = proxyField
        end
        dataSources[libInnerName] = dataSource
    end

    return dataSourceProxy
end

local createDataSourceDefinition = function(data)
    dataSourceDefinitions[data.name] = dataSourceProxyFactory(data)
end

local connectLib = function(data)
    local libReference = data.lib
    local definition = data.definition
    local libInnerName = data.libInnerName
    local dataSourceProxy = dataSourceProxyFactory(definition)
    dataSourceProxy:connect(libReference, libInnerName)
    print(data.lib, "connected", dataSourceDefinitions[definitionName], libInnerName)
end

uiApi.getDataSource = function(self, libInnerName)
    return dataSources[libInnerName]
end

uiApiController.subscriptions["uiApiOverlapped"] = setOverlapped
uiApiController.subscriptions["uiApiInputCords"] = setInputCords
uiApiController.subscriptions["integrateUiApi"] = integrateUiApi
uiApiController.subscriptions["uiApiInit"] = initApi

uiApiController.subscriptions["registerDataSourceDefinition"] = createDataSourceDefinition
uiApiController.subscriptions["connectExternalLib"] = connectLib


return uiApiController
