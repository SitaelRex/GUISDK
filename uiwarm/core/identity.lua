local identity = {}

local convertTable = {
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w",
    "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
    "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}

local generateIdentityName = function(num)
    local numstr = tostring(num)
    local result = ""
    for i = 1, #numstr do
        local index = tonumber(numstr:sub(i, i + 1))
        if not convertTable[index + 1] then
            index = tonumber(numstr:sub(i, i))
        end
        result = result .. convertTable[index + 1]
    end
    return result
end

local defineIdentity = function(self)
    local result = {}
    result.name = generateIdentityName(math.random(100000000, 9999999999))
    return result
end

identity.setIdentity = function(self, identityName)
    self.name = identityName
end

setmetatable(identity, { __call = defineIdentity })
return identity
