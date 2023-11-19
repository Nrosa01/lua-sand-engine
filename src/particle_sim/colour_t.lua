-- colour_t.lua
local ffi = require("ffi")

ffi.cdef[[
    struct colour_t {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    };
]]

return ffi.typeof("struct colour_t")
