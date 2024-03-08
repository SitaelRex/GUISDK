local hierarchy = {}

local defineHierarchy = function(self, params)
    local result = {}
    result.builder = self
    result.parent = nil
    result.childs = {}
    return result
end

hierarchy.insert = function(self, buildable)
    self.builder.buildQueue[#self.builder.buildQueue + 1] = buildable
end

setmetatable(hierarchy, { __call = defineHierarchy })
return hierarchy
