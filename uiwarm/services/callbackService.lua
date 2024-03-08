local callbackService              = {}

local elementLinks                 = {} --ссылки на объекты и их колбеки

local currentHover                 = nil
local currentTransparentHovers     = nil
local collisionTree                = nil
local cachedHover                  = nil
local cachedPress                  = nil
local overlapped                   = nil
local dragged                      = nil
local hoverFocus                   = { element = nil, trigger = nil }
local currentFocus                 = nil

local uiApi                        = {}
local getUIApi                     = function()
    return uiApi
end

local elements                     = {
}

local eventHandleMode              = {
}

local handleAll                    = function(data)
    if elementLinks[data.eventName] then
        for element, elementData in pairs(elementLinks[data.eventName]) do
            for _, callback in pairs(elementData) do
                callback.invoke(element, callback.params, getUIApi())
            end
        end
    end
end

local handleUnhovered              = function(data)
    if elementLinks[data.eventName] then
        for element, elementData in pairs(elementLinks[data.eventName]) do
            if element ~= currentHover then
                local isTransparentToo = false
                if currentTransparentHovers and currentTransparentHovers[element] then
                    isTransparentToo = elementLinks["onTransparentHover"][element]
                end

                if not isTransparentToo then
                    for _, callback in pairs(elementData) do
                        callback.invoke(element, callback.params, getUIApi())
                    end
                end
            end
        end
    end
end

local handleHovered                = function(data)
    local targetElement = currentHover
    if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi())
        end
    end
end

local cachePos                     = {}
local handleHoveredCacheHover      = function(data)
    cachedHover = currentHover
    if cachedHover ~= "emptyData" and currentHover then
        cachePos.x = currentHover.content.x
        cachePos.y = currentHover.content.y

        local targetElement = cachedHover
        if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
            for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
                callback.invoke(targetElement, callback.params, getUIApi())
            end
        end
    end
end

local handleHoveredCachedHover     = function(data)
    local targetElement = cachedHover
    if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        dragged = targetElement
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi())
        end

        if dragged.content.x ~= cachePos.x or dragged.content.y ~= cachePos.y then
            cachedPress = "Error"
        end
    end
end

local handleHoveredUncacheHover    = function(data)
    dragged = nil

    local targetElement = cachedHover
    if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi())
        end
    end
    overlapped = nil
end

local handleHoveredCachePress      = function(data)
    cachedPress = not cachedPress and currentHover or cachedPress
    if cachedPress ~= currentHover then cachedPress = "Error" end
    currentFocus = currentHover

    local targetElement = currentHover
    if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi())
        end
    end
end

local handleHoveredCachePressCheck = function(data)
    currentFocus = nil
    if cachedPress ~= "Error" then
        local targetElement = currentHover
        if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
            cachedPress = "Error"
            for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
                callback.invoke(targetElement, callback.params, getUIApi())
            end
        end

        for k, element in pairs(elements[data.eventName]) do
            if element.element == currentHover then
                if cachedPress ~= "Error" then
                    cachedPress = "Error"
                    element.callback(element.element, getUIApi())
                end
            end
        end
    end
    cachedPress = nil
    currentFocus = currentHover
end

local handleParamList              = function(data)
    if elementLinks[data.eventName] and elementLinks[data.eventName][data.params] then
        for element, elementData in pairs(elementLinks[data.eventName]) do
            if element == data.params then
                for _, callback in pairs(elementData) do
                    callback.invoke(element, callback.params, getUIApi(), data.params.key)
                end
            end
        end
    end
end

local handleTransparent            = function(data)
    if elementLinks[data.eventName] then
        local targetElement = currentTransparentHovers
        for element, v in pairs(targetElement) do
            if element and elementLinks[data.eventName] and elementLinks[data.eventName][element] then
                for _, callback in pairs(elementLinks[data.eventName][element]) do
                    callback.invoke(element, callback.params, getUIApi())
                end
            end
        end
    end
end

local handleDestroy                = function(data)
    if elementLinks[data.eventName] then
        local targetElement = data.params
        if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
            for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
                callback.invoke(targetElement, callback.params, getUIApi())
            end
        end
    end
    -- удаляем элемент из всех списков колбеков
    for eventName, eventList in pairs(elementLinks) do
        eventList[data.params] = nil
    end
end

local handleData                   = function(data)
    if elementLinks[data.eventName] then
        local targetElement = data.params
        if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
            for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
                callback.invoke(targetElement, callback.params, getUIApi())
            end
        end
    end
end

local intersect                    = function(t1, t2)
    local a = { x = t1.content.x, x1 = t1.content.x + t1.content.w, y = t1.content.y, y1 = t1.content.y + t1.content.h }
    local b = { x = t2.content.x, x1 = t2.content.x + t2.content.w, y = t2.content.y, y1 = t2.content.y + t2.content.h }
    local s1 = (a.x >= b.x and a.x <= b.x1) or (a.x1 >= b.x and a.x1 <= b.x1)
    local s2 = (a.y >= b.y and a.y <= b.y1) or (a.y1 >= b.y and a.y1 <= b.y1)
    local s3 = (b.x >= a.x and b.x <= a.x1) or (b.x1 >= a.x and b.x1 <= a.x1)
    local s4 = (b.y >= a.y and b.y <= a.y1) or (b.y1 >= a.y and b.y1 <= a.y1)
    return ((s1 and s2) or (s3 and s4)) or ((s1 and s4) or (s3 and s2));
end

local checkOverlapTrigger          = function(overlapped, trigger)
    -- проверяет, что логика overlap будет выполняться только для того объекта, триггер которого есть у перетаскиваемого объекта
    for groupName, _ in pairs(overlapped.collision.overlapGroup) do
        if trigger.collision.overlapTrigger[groupName] then
            return true
        end
    end
end

local handleOverlap                = function(data)
    if currentHover == dragged and cachedPress and dragged then
        local indexInTree = { idx = 0, element = nil }

        for element, elementData in pairs(elementLinks[data.eventName]) do
            local idx = 0
            for i = 1, #collisionTree do
                local k = i
                local v = collisionTree[i]
                if v == element and intersect(element, dragged) then
                    idx = k
                end
                if indexInTree.idx < idx then
                    indexInTree = { idx = idx, element = element, elementData = elementData }
                end
            end
        end

        if indexInTree.element and checkOverlapTrigger(indexInTree.element, dragged) and dragged == currentHover then
            for _, callback in pairs(indexInTree.elementData) do
                callback.invoke(indexInTree.element, callback.params, getUIApi())
            end
        end
        overlapped = indexInTree.element or nil
    end
end

local handleNotOverlap             = function(data)
    if elementLinks[data.eventName] then
        for element, elementData in pairs(elementLinks[data.eventName]) do
            for _, callback in pairs(elementData) do
                if element ~= overlapped then
                    callback.invoke(element, callback.params, getUIApi())
                end
            end
        end
    end
end

local handleAttach                 = function(data)
    local targetElement = data.params.source
    if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi(), data.params.attached)
        end
    end
end

local handleDetach                 = function(data)
    local targetElement = data.params.source
    if elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi(), data.params.detached)
        end
    end
end


local handleMove = function(data)
    local targetElement = data.params
    if elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi())
        end
    end
end

local handleWindowResize = function(data)
    for element, elementData in pairs(elementLinks[data.eventName]) do
        for _, callback in pairs(elementData) do
            callback.invoke(element, callback.params, getUIApi(), data.params)
        end
    end
end

local handleResize = function(data)
    local targetElement = data.params
    if elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi())
        end
    end
end


local handleTextInput = function(data)
    if elementLinks[data.eventName] then
        for element, elementData in pairs(elementLinks[data.eventName]) do
            for _, callback in pairs(elementData) do
                callback.invoke(element, callback.params, getUIApi(), data.params.key)
            end
        end
    end
end

local handleWheelMove = function(data)
    local targetElement = hoverFocus.element

    if not targetElement then
        for el, v in pairs(currentTransparentHovers) do
            targetElement = el
            if elementLinks["onWheelMoved"][el] then
                for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
                    callback.invoke(targetElement, callback.params, getUIApi(), data.params.x, data.params.y)
                end
            end
        end
    end
    if targetElement and elementLinks[data.eventName] and elementLinks[data.eventName][targetElement] then
        for _, callback in pairs(elementLinks[data.eventName][targetElement]) do
            callback.invoke(targetElement, callback.params, getUIApi(), data.params.x, data.params.y)
        end
    end
end
-----------------------------------------------

local handleCallback = function(data)
    if eventHandleMode[data.eventName] then
        eventHandleMode[data.eventName](data)
    end
end

--Инвокер позволяет множественные коллбеки
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

local listenElement = function(element)
    local callbacks = element.callback.callbacks
    local params = element.callback.params
    for callbackName, callbackFunctions in pairs(callbacks) do
        elementLinks[callbackName] = elementLinks[callbackName] or {}
        elementLinks[callbackName][element] = elementLinks[callbackName][element] or {}
        table.insert(elementLinks[callbackName][element], invokerFactory(callbackFunctions, params[callbackName]))
    end
end

local removeFromListen = function(data)

end

local handleUiApi = function(api)
    uiApi = api
end

local updateHover = function(data)
    currentHover = data.current

    if currentHover ~= hoverFocus.trigger and data.transparent[#data.transparent] ~= hoverFocus.trigger then
        hoverFocus = { element = nil, trigger = nil }
    end
    currentTransparentHovers = data.transparent
    collisionTree = data.tree
end

local updateHoverFocus = function(self, data)
    -- для работы слайдеров при наведении на родительский элемент
    hoverFocus = { element = data.element, trigger = data.trigger }
end

local callbackConfig = {
    onPress = handleHoveredCachePress,
    onTransparentPress = handleTransparent,
    onRelease = handleHoveredCachePress,
    onClick = handleHoveredCachePressCheck,
    onTransparentClick = handleTransparent,
    onHover = handleHovered,
    onTransparentHover = handleTransparent,
    onNotHover = handleUnhovered,
    onDragStart = handleHoveredCacheHover,
    onDrag = handleHoveredCachedHover,
    onDragEnd = handleHoveredUncacheHover,
    update = handleAll,
    onCreate = handleParamList,
    onCreateB = handleParamList,
    onDestroy = handleDestroy,
    onOverlap = handleOverlap,
    onDestroyB = handleData, -- стандартный
    onNotOverlap = handleNotOverlap,
    onAttach = handleAttach,
    onDetach = handleDetach,
    onMove = handleMove,
    onResize = handleResize,
    onWindowResize = handleWindowResize,
    onTextInput = handleTextInput,
    onWheelMoved = handleWheelMove,
}

local getCallbackConfig = function(self)
    elements = {}
    eventHandleMode = {}

    for eventName, eventFunc in pairs(callbackConfig) do
        elements[eventName] = {}
        eventHandleMode[eventName] = eventFunc
    end
    return callbackConfig
end

local setCallbacks = function(data)
    elementLinks = nil
    elementLinks = data
end

local configureCallbacks = function(self, callbacks)

end

local getOverlapped = function()
    return overlapped
end

callbackService.getCallbackConfig = getCallbackConfig
callbackService.handleUiApi = handleUiApi
callbackService.handleCallback = handleCallback
callbackService.listenElement = listenElement
callbackService.updateHover = updateHover
callbackService.removeFromListen = removeFromListen
callbackService.getOverlapped = getOverlapped
callbackService.updateHoverFocus = updateHoverFocus
callbackService.setCallbacks = setCallbacks

return callbackService
