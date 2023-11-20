-- Particle.lua
local ffi = require("ffi")

ffi.cdef[[
    struct Particle {
        uint32_t type;
        bool clock;
    };
]]

local Particle = ffi.metatype("struct Particle", {})

return Particle
