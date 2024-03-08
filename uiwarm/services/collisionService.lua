local collisionService = {}

local sceneInterpretation = {}
local currentCollision = nil
local transparentCollision = nil
local collisionTree = nil

local sceneStateUpdate = function(self, data)
    sceneInterpretation = data
end

local checkCollision = function(element, x, y)
    local content = element.content
    return element.collision.checkCollision and (element.collision.predicate(x, y, content) and element) or nil
end

local handleElement

handleElement = function(element, result, x, y, transparentCollision, check)
    local childResult = nil
    local elementCollisionAccept = checkCollision(element, x, y)
    if elementCollisionAccept then
        local childsList = {}
        local check = check
        for _, child in pairs(element.childs) do
            table.insert(childsList, 1, child)
        end
        for _, child in pairs(childsList) do
            if childResult then
                check = false
            end
            local res = handleElement(child, result, x, y, transparentCollision, check)
            if not childResult then
                childResult = res
            end
        end
        table.insert(collisionTree, 1, element)
    end
    result = childResult or elementCollisionAccept
    if childResult and elementCollisionAccept and check then
        transparentCollision[element] = true
    end
    return result
end

local collisionUpdate = function(self, checkCords)
    collisionTree = {}
    transparentCollision = {}
    local x, y = checkCords.x, checkCords.y
    local resultCollision

    local childsList = {}
    for _, child in pairs(sceneInterpretation) do -- обратный порядок проверки коллизии
        table.insert(childsList, 1, child)
    end

    for _, element in pairs(childsList) do
        local check = resultCollision and false or true
        local result = handleElement(element, newCollision, x, y, transparentCollision, check)
        if not resultCollision then
            local newCollision = result
            if newCollision and not resultCollision then
                resultCollision = newCollision
            end
        end
    end
    currentCollision = resultCollision or nil
end

--возвращает найденную коллизию
local getCollision = function()
    return { current = currentCollision, transparent = transparentCollision, tree = collisionTree }
end

collisionService.sceneStateUpdate = sceneStateUpdate
collisionService.collisionUpdate = collisionUpdate
collisionService.getCollision = getCollision

return collisionService
