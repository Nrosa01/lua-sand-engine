package.path = package.path .. "./libs/?.lua"

-- Set filtering to nearest to avoid blurring
love.graphics.setDefaultFilter("nearest", "nearest")