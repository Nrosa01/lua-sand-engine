require "buffer"

local f = ...

f = Decode(f)

if not f then
    print("Not f")
    return
end

print(f:getRegisteredParticlesCount())

-- print(f:getRegisteredParticlesCount())

-- load f as function (f is a string)
-- local func = Decode(f)

-- -- call the function
-- func()