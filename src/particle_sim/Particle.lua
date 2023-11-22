local ffi = require("ffi")

---@class Particle
---@alias Particle* Particle*
ffi.cdef [[
typedef struct { uint8_t type; bool clock; } Particle;
]]

local Particle = ffi.metatype("Particle", {})

return Particle