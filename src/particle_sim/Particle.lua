-- Particle.lua
local ffi = require("ffi")

ffi.cdef[[
    struct Particle {
        uint32_t type;
        int temperature;
        uint8_t random_granularity;
        bool clock;
        uint32_t life_time;
    };
]]

return ffi.typeof("struct Particle")
