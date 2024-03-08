local sceneService = {}

local scene = {}
local callbackInvokers = {}
local recursiveGetDestroyed

recursiveGetDestroyed = function(element, result)
    table.insert(result, 1, element)
    for k, v in pairs(element.childs) do
        recursiveGetDestroyed(v, result)
    end
end

local detached = {}
local getNewDetached = function()
    return detached
end

local defineSelfDistruct = function(element)
    element.destroy = function(self)
        local result = {}
        recursiveGetDestroyed(self, result)
        for k, v in pairs(result) do
            table.insert(detached, v.parent)
            callbackInvokers:get("onDestroy")(v)
            print("destroyed", v.identity.name)
            callbackInvokers:get("onDestroy")(v)
            v:callbackDestroy()
            v:onDestroy()
        end
    end

    element.callbackDestroy = function(self)
        local target = self.parent and self.parent.childs or scene
        local baseIndex = nil
        for k, element in pairs(target) do
            baseIndex = element == self and k or baseIndex
        end
        table.remove(target, baseIndex)
    end
end

local defineSelfSetTopLayer = function(element)
    element.setTopLayer = function(self)
        local parentPool = self.parent and self.parent.childs or scene
        local baseIndex = nil
        for k, element in pairs(parentPool) do
            baseIndex = element == self and k or baseIndex
        end
        table.remove(parentPool, baseIndex)
        table.insert(parentPool, self)
    end
end

local defineDetach = function(element)
    element.detach = function(self)
        local parent = self.parent
        local parentPool = self.parent and self.parent.childs or scene
        local baseIndex = nil
        for k, element in pairs(parentPool) do
            baseIndex = element == self and k or baseIndex
        end
        table.remove(parentPool, baseIndex)
        table.insert(scene, self)
        self.parent = nil
        table.insert(detached, { source = parent, detached = self })
    end
end

local attached = {}
local getNewAttached = function()
    return attached
end

local defineAttach = function(element)
    element.attach = function(self, attachedElement)
        attachedElement.parent = self
        table.insert(self.childs, attachedElement)
        scene[#scene] = nil
        table.insert(attached, { source = self, attached = attachedElement })
    end
end

local moved = {}
local getNewMoved = function()
    return moved
end

local defineMove = function(element)
    element.moveTo = function(self, cords)
        -- self:setCords(cords)
        self.content.x = cords.x
        self.content.y = cords.y
        table.insert(moved, self)
    end
end

local resized = {}
local getNewResized = function()
    return resized
end

local defineResize = function(registryId)

end

local insertToScene = function(self, element)
    if element.parent then
        element.content.x = element.content.x + element.parent.content.x
        element.content.y = element.content.y + element.parent.content.y
        table.insert(element.parent.childs, element)
    else
        table.insert(scene, element)
    end
    defineSelfDistruct(element)
    defineSelfSetTopLayer(element)
    defineDetach(element)
    defineAttach(element)
    defineMove(element)
    defineResize(element)
end

local clearScene = function(self)
    for k, v in pairs(scene) do
        v:destroy()
    end
end

local recursiveCountScene
recursiveCountScene = function(t, counter)
    for k, v in pairs(t) do
        counter = counter + 1
        counter = recursiveCountScene(v.childs or {}, counter)
    end
    return counter
end

local getScene = function()
    return scene
end

local setCallbackInvokers = function(self, invokers)
    callbackInvokers = {}
    callbackInvokers.invokers = {}
    callbackInvokers.get = function(self, callbackName)
        return self.invokers[callbackName]
    end
    for k, v in pairs(invokers) do
        callbackInvokers.invokers[k] = v
    end
end

sceneService.getNewMoved = getNewMoved
sceneService.getNewResized = getNewResized
sceneService.getScene = getScene
sceneService.getNewAttached = getNewAttached
sceneService.getNewDetached = getNewDetached
sceneService.insertToScene = insertToScene
sceneService.setCallbackInvokers = setCallbackInvokers
sceneService.clearScene = clearScene

return sceneService
