local ffi = require("ffi")
local Particle = require("Particle")

-- Receive values sent via thread:start
local chunk = ...
local ptr = ffi.cast("Particle*", chunk:getFFIPointer())
ptr[0].type = 2
print("Chunk test " .. ptr[0].type)