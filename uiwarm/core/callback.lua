local callback = {}

local removeCallbackById = function(self, callbackType, id)
    if self.callbacks[callbackType] then
        self.callbacks[callbackType][id] = nil
    end
end

local createCallback = function(self, params)
    local result = {}
    result.callbacks = {}
    result.params = {}
    result.renderCallback = nil
    result.removeCallbackById = removeCallbackById
    return result
end

callback.defCallback = function(self, callbackName, func, params, callbackId)
    self.callbacks[callbackName] = self.callbacks[callbackName] or {}
    local callbackId = callbackId or #self.callbacks[callbackName] + 1
    self.callbacks[callbackName][callbackId] = func
    self.params[callbackName] = self.params[callbackName] or {}
    self.params[callbackName][callbackId] = params
end

callback.defRenderCallback = function(self, func, params)
    self.renderCallback = function(entityself, ...) return func(entityself, params or {}, ...) end
end

setmetatable(callback, { __call = createCallback })
return callback
