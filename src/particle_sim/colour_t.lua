-- colour_t.lua
local ffi = require("ffi")

---@class colour_t
---@field r number
---@field g number
---@field b number
---@field a number
ffi.cdef[[
    typedef struct {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } colour_t;
]]

return ffi.typeof("colour_t")
