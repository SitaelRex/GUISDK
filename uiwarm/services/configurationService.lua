local PATH = (...):gsub('%/[^%/]+$', '')
local ROOT = PATH:gsub('%/[^%/]+$', ''):gsub('%/[^%/]+$', '')

local builder

local configurationService = {}

local builderTemplate = require(ROOT .. "/wrappers/builder")
local modules = {
    callback = require(ROOT .. "/core/callback"),
    content = require(ROOT .. "/core/content"),
    identity = require(ROOT .. "/core/identity"),
    variables = require(ROOT .. "/core/variables"),
    collision = require(ROOT .. "/core/collision"),
    stateMachine = require(ROOT .. "/core/stateMachine")
}


local handleExtensions = function(extensionModules)
    if type(extensionModules) == "table" then
        for modName, mod in pairs(extensionModules) do
            modules[modName] = mod
        end
    end
end

local configuredSources = {}

local getConfiguredDataSources = function()
    return configuredSources
end

local dataSource = {}

dataSource.build = function(template)
    local result = {}
    result.data = template.struct
    result.emit = function(self, data)
        return template.func(data, result.data)
    end

    return result
end

local configureDataSources = function(self, sources)
    if sources then
        for k, v in pairs(sources) do
            configuredSources[k] = dataSource.build(v)
        end
    end
end


local configureBuilder = function(serviceSelf, extensionModules, uiApiRef)
    local result = builderTemplate
    local builderFunctions, moduleFunctionDictionary = builderTemplate:getInstanceConfig()
    local moduleInstances = {}

    for moduleName, moduleTemplate in pairs(modules) do
        moduleInstances[moduleName] = moduleTemplate
        if type(moduleTemplate) == "table" then
            for funcName, func in pairs(moduleTemplate) do
                local configuredfunc = function(self, ...)
                    self.buildableElement[moduleName].elementRef = self.buildableElement
                    self.buildableElement[moduleName].uiApiRef = uiApiRef
                    func(self.buildableElement[moduleName], ...)
                    return self
                end
                builderFunctions[funcName] = configuredfunc
                moduleFunctionDictionary[moduleName] = funcName
            end
        end
    end

    result:setModuleTemplates(moduleInstances)

    result.tag = "builder"
    return result
end

local setBuilder = function(self, configuredbuilder)
    assert(configuredbuilder.tag == "builder", "builder must have tag 'builder'")
    builder = configuredbuilder
end

local getBuilder = function(self)
    return builder
end

configurationService.setDataSources = setDataSources
configurationService.setBuilder = setBuilder
configurationService.getBuilder = getBuilder
configurationService.configureBuilder = configureBuilder
configurationService.configureDataSources = configureDataSources
configurationService.getConfiguredDataSources = getConfiguredDataSources
return configurationService
