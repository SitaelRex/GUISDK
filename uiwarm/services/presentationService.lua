local presentationService = {}

local presentation = {}
local nextFrameCallbacks = {}
local apiUi
local handleChilds, handleElement

local cropOutOfBounds = function(c, parentBorders)
    local finalX = c.x
    local finalY = c.y
    local finalW = c.w
    local finalH = c.h

    if c.x < parentBorders.x then
        finalX = parentBorders.x

        finalW = c.w - (parentBorders.x - c.x)
        finalW = finalW > 0 and finalW or 0
    end

    if c.x > parentBorders.x + parentBorders.w then
        finalX = parentBorders.x + parentBorders.w
        finalW = 0
    end

    if c.y < parentBorders.y then
        finalY = parentBorders.y

        finalH = c.h - (parentBorders.y - c.y)
        finalH = finalH > 0 and finalH or 0
    end

    if c.y > parentBorders.y + parentBorders.h then
        finalY = parentBorders.y + parentBorders.h
        finalH = 0
    end

    if finalX + finalW > parentBorders.x + parentBorders.w then
        finalW = finalW - ((finalX + finalW) - (parentBorders.x + parentBorders.w))
    end

    if finalY + finalH > parentBorders.y + parentBorders.h then
        finalH = finalH - ((finalY + finalH) - (parentBorders.y + parentBorders.h))
    end

    return finalX, finalY, finalW, finalH
end

local invokerFactory = function(functionList, paramsList)
    local result = {
        invoke = function(elementSelf, params, uiApi, ...)
            for key, func in pairs(functionList) do
                local params = paramsList[key]
                func(elementSelf, params, uiApi, ...)
            end
        end
        ,
        params = paramsList
    }
    return result
end

local handleCallbacks = function(element)
    local callbacks = element.callback.callbacks
    local params = element.callback.params
    for callbackName, callbackFunctions in pairs(callbacks) do
        nextFrameCallbacks[callbackName] = nextFrameCallbacks[callbackName] or {}
        nextFrameCallbacks[callbackName][element] = nextFrameCallbacks[callbackName][element] or {}
        table.insert(nextFrameCallbacks[callbackName][element], invokerFactory(callbackFunctions, params[callbackName]))
    end
end
handleChilds = function(childs, result, parentBorders)
    if #childs == 0 then return result end
    for _, child in pairs(childs) do
        result = handleElement(child, result, parentBorders)
    end
    return result
end

handleElement = function(element, result, parentBorders)
    local parentBorders = parentBorders or
        { x = 0, y = 0, w = element.content.w, h = element.content.h } 
    local c = element.content
    local layer = 1                                              
    result[layer] = result[layer] or {}
    local elCallback = element.callback and element.callback.renderCallback or function() end
    local callback = function(...)
        return elCallback(...)
    end
    local finalX, finalY, finalW, finalH = cropOutOfBounds(c, parentBorders)

    if finalW > 1 and finalH > 1 then
        local presentationElement = {
            x = finalX,
            y = finalY,
            w = finalW,
            h = finalH,
            content = element.content,
            configuredCallback = callback,
            parent = element.parent,
            childs = element.childs,
            variables = element.variables
        }
        table.insert(result[layer], presentationElement)
        --вместо послойного представления просто очередь отрисовки
        local newParentBorders = { x = finalX, y = finalY, w = finalW, h = finalH }
        result = handleChilds(element.childs, result, newParentBorders)
        handleCallbacks(element)
    end
    return result
end

local updatePresentation = function(self, scene)
    nextFrameCallbacks = {}

    local result = {}
    for i = 1, #scene do
        result = handleElement(scene[i], result)
    end
    presentation = result
end

local getPresentation = function()
    return presentation
end

local getNextFrameCallbacks = function()
    return nextFrameCallbacks
end

local handleUiApi = function(api)
    apiUi = api
end

presentationService.getNextFrameCallbacks = getNextFrameCallbacks
presentationService.getPresentation = getPresentation
presentationService.updatePresentation = updatePresentation
presentationService.handleUiApi = handleUiApi
return presentationService
