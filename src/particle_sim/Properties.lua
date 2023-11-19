-- Properties.lua
local ffi = require("ffi")

ffi.cdef[[
    struct Properties {
        int density;
        int flammability;
        int explosiveness;
        int boilingPoint;
        int startingTemperature;
    };
]]

return ffi.typeof("struct Properties")
