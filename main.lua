local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
    lldebugger = require("lldebugger")
    lldebugger.start()

    function love.errorhandler(msg)
        error(msg, 2)
    end
end

local mouse = nil
local canvas_size = 800
local brush_size = math.floor(canvas_size / 20);

require "src"
require "ParticleDefinitionsHandler"
require "particleLauncher"
require "quad"
require "particle_chunk"

local myQuad;
local chunk;

function love.load()
    -- create quad with the same size as the window getting the size from the window
    myQuad = Libs.Quad:new(love.graphics.getWidth(), love.graphics.getHeight(), canvas_size, canvas_size)
    chunk = ParticleChunk.new(canvas_size, canvas_size, myQuad)
end

function love.update(dt)
	if (mouse ~= nil and mouse.button == "left") then
		for x = -brush_size, brush_size do
			for y = -brush_size, brush_size do
                local px = mouse.x + x
                local py = mouse.y + y
                if chunk:isInside(px, py) and chunk:isEmpty(px, py) then
                    chunk:setNewParticleById(px, py, 2)
                end
			end
		end
	end

    chunk:update()
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Checks which button was pressed.
    local buttonname = ""
    if button == 1 then
        buttonname = "left"
    elseif button == 2 then
        buttonname = "right"
    end

    local chunkX = math.floor(x / (love.graphics.getWidth() / chunk.width)) + 1
    local chunkY = math.floor(y / (love.graphics.getHeight() / chunk.height)) + 1
    mouse = { x = chunkX, y = chunkY, button = buttonname }
end

function love.mousemoved(x, y, dx, dy)
	if mouse ~= nil then
        local chunkX = math.floor(x / (love.graphics.getWidth() / chunk.width)) + 1
        local chunkY = math.floor(y / (love.graphics.getHeight() / chunk.height)) + 1
        mouse = { x = chunkX, y = chunkY, button = mouse.button }
	end
end

function love.mousereleased(x, y, button, istouch)
	-- Checks which button was pressed.
	local buttonname = ""
	mouse = nil
end

function love.draw()
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
