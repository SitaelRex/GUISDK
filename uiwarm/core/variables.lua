local variables = {}

local set = function(self, varname, varvalue)
    if self.storage[varname] and type(self.storage[varname]) == "table" and self.storage[varname].set then
        self.storage[varname]:set(varvalue)
    else
        self.storage[varname] = varvalue
    end
end

local get = function(self, varname)
    if self.storage[varname] and type(self.storage[varname]) == "table" and self.storage[varname].get then
        return self.storage[varname]:get(varname)
    else
        return self.storage[varname]
    end
end

local defineVariables = function(self)
    local result = {}
    result.storage = {}

    result.get = get
    result.set = set
    return result
end

variables.variable = function(self, varname, varStartValue)
    self:set(varname, varStartValue)
end

setmetatable(variables, { __call = defineVariables })

return variables
