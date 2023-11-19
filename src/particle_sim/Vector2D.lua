-- Vector2D.lua
local ffi = require("ffi")

ffi.cdef[[
    struct Vector2D {
        float x;
        float y;
    };
]]

return ffi.typeof("struct Vector2D")
