require "buffer"

local f = ...

f = Decode(f)

if not f then
    print("Not f")
    return
end

print(f:getRegisteredParticlesCount())