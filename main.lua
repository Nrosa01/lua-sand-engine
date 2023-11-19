require "src"
require "ParticleDefinitionsHandler"
require "particleLauncher"
require "quad"
require "particle_chunk"

local myQuad;
local chunk;

function love.load()
    -- Set windows size to 800*800
    love.window.setMode(800, 800)
    -- create quad with the same size as the window getting the size from the window
    myQuad = Libs.Quad:new(love.graphics.getWidth(), love.graphics.getHeight(), 100, 100)
    chunk = ParticleChunk.new(100, 100)

    print(ParticleDefinitionsHandler:getRegisteredParticlesCount())
end

function love.update(dt)
    chunk:update()
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- Convert mouse coordinates to chunk coordinates and set the particle type to 2
        local chunkX = math.floor(x / (love.graphics.getWidth() / chunk.matrix.width)) + 1
        local chunkY = math.floor(y / (love.graphics.getHeight() / chunk.matrix.height)) + 1
        chunk:setNewParticleById(chunkX, chunkY, 2)
    end
end

function love.draw()
    -- Iterate all particles in the chunk and draw them
    for x = 1, chunk.matrix.width - 1 do
        for y = 1, chunk.matrix.height - 1 do
            local particle = chunk.matrix.data[x][y]
            local particle_color = ParticleDefinitionsHandler:getParticleData(particle.type).particle_color
            -- If particle type is not 0 print the type
            if particle.type ~= 1 then
                myQuad:setPixel(x, y, particle_color.r, particle_color.g, particle_color.b, particle_color.a)
            end
        end
    end

    myQuad:render(0, 0)
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS() .. " GC: " .. gcinfo()), 10, 10)
end

function love.filedropped(file)
    -- Only run if the file is a lua file
    if file:getExtension() == "lua" then
        local fileRunner = require "fileRunner"
        fileRunner(file)
    else
        -- Show an error message as a popup (later I should make this a toast)
        local message = "The file you dropped is not a lua file"
        love.window.showMessageBox("Error", message, "error")
    end
end

