-- Empty def
local class = {}

-- This feels ugly
class.__index = class

function class:new()
    -- I guess here I define fields
    local o = 
    {
        value = 0,
        text = "Hello World!",
    }

    setmetatable(o, self)
    return o
end

function class:print(value)
    print(value)
end

return class