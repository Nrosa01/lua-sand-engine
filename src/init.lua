package.path = package.path .. "./src/libs/?.lua;./src/?.lua;./src/particle_sim/?.lua"

-- Set filtering to nearest to avoid blurring
love.graphics.setDefaultFilter("nearest", "nearest")

Libs = {}