local collision = {}

local basicPredicate = function(x, y, content)
    return (x >= content.x and x <= content.x + content.w and
        y >= content.y and y <= content.y + content.h) and true or false
end

local createCollision = function(self, params)
    local result = {}
    result.predicate = basicPredicate
    result.checkCollision = true
    result.overlapGroup = {}
    result.overlapTrigger = {}
    return result
end

collision.defCollisionPredicate = function(self, predicate)
    self.predicate = predicate
end

collision.enableCollision = function(self)
    self.checkCollision = true
end

collision.disableCollision = function(self)
    self.checkCollision = false
end

collision.setCollisionGroup = function(self, name)
    self.overlapGroup[name] = true
end

collision.removeCollisionTriggers = function(self)
    self.overlapTrigger = {}
end

collision.setCollisionTrigger = function(self, name)
    self.overlapTrigger[name] = true
end

setmetatable(collision, { __call = createCollision })
return collision
