local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
    lldebugger = require("lldebugger")
    lldebugger.start()

    function love.errorhandler(msg)
        error(msg, 2)
    end
end

local mouse = { x = 0, y = 0, button = "" }
local canvas_size = 400
local brush_size = math.floor(canvas_size / 20);
local sensitivy = brush_size / 10
local currentParticle = 2

local imgui = require "imgui"
local ffi = require "ffi"
require "src"
require "ParticleDefinitionsHandler"
require "particleLauncher"
local Quad = require "quad"
local ParticleChunk = require "particle_chunk"
require "buffer"

local classTemplate = require "classTemplate"

local myQuad;
local chunk;

local thread

local t = function () print "hey" end

--cdef struct that just holds a pointer to void
ffi.cdef [[
    typedef struct {
        void* ptr;
    } void_ptr;
]]

function love.load()
    -- create quad with the same size as the window getting the size from the window
    myQuad = Quad:new(love.graphics.getWidth(), love.graphics.getHeight(), canvas_size, canvas_size)
    chunk = ParticleChunk:new(canvas_size, canvas_size, myQuad)

    -- asign the function to the pointer

    thread = love.thread.newThread("src/particle_sim/simulateFromThread.lua")
    local newClass = classTemplate:new()
    newClass:print("Im primting from main")
    local imageData = myQuad.imageData
    -- thread:start({bytecode = chunk.bytecode, width = chunk.width, height = chunk.height}, imageData, Encode(ParticleDefinitionsHandler))        
    print("Chunk test " .. chunk.matrix[0].type)
end

local function drawParticleMenu()
    local count = ParticleDefinitionsHandler:getRegisteredParticlesCount()

    imgui.Begin("Material selector", true, { "ImGuiWindowFlags_AlwaysAutoResize" });

    for i = 1, count do
        local data = ParticleDefinitionsHandler:getParticleData(i)

        if imgui.Selectable(data.text_id, currentParticle == i) then
            currentParticle = i
        end
        imgui.SameLine()
        imgui.ColorButton(data.text_id .. "Color", data.color.r, data.color.g, data.color.b, data.color.a)
    end

    imgui.End()
end

local function selectFromInput(input)
    local pressedChar = string.lower(input)
    local startIdx = currentParticle
    local found = false

    repeat
        startIdx = (startIdx % ParticleDefinitionsHandler:getRegisteredParticlesCount()) + 1
        local data = ParticleDefinitionsHandler:getParticleData(startIdx)
        local dataChar = string.lower(data.text_id:sub(1, 1))

        if dataChar == pressedChar then
            currentParticle = startIdx
            found = true
            break
        end
    until startIdx == currentParticle

    if not found then
        -- No particle found, we could play a sound or something here idk
    end
end

function love.keypressed(key, scancode, isrepeat)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        selectFromInput(key)
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.update(dt)
    imgui.NewFrame()

    if (mouse ~= nil and mouse.button == "left") then
        local centerX, centerY = mouse.x, mouse.y

        for x = -brush_size, brush_size do
            for y = -brush_size, brush_size do
                local px = mouse.x + x
                local py = mouse.y + y

                -- Verifica si la posición (px, py) está dentro del círculo
                local distanceSquared = (px - centerX) ^ 2 + (py - centerY) ^ 2
                if chunk:isInside(px, py) and distanceSquared <= brush_size ^ 2 and (chunk:isEmpty(px, py) or currentParticle == 1) then
                    chunk:setNewParticleById(px, py, currentParticle)
                end
            end
        end
    end


    chunk:update()
end

function love.quit()
    imgui.ShutDown()
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        if y > 0 then
            brush_size = brush_size + sensitivy
        elseif y < 0 then
            brush_size = brush_size - sensitivy
            -- use math.max to avoid negative values
            brush_size = math.max(brush_size, 1)
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Checks which button was pressed.
        local buttonname = ""
        if button == 1 then
            buttonname = "left"
        elseif button == 2 then
            buttonname = "right"
        end

        local chunkX = math.floor(x / (love.graphics.getWidth() / chunk.width))
        local chunkY = math.floor(y / (love.graphics.getHeight() / chunk.height))
        mouse = { x = chunkX, y = chunkY, button = buttonname }
    end
end

function love.mousemoved(x, y, dx, dy)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        local chunkX = math.floor(x / (love.graphics.getWidth() / chunk.width))
        local chunkY = math.floor(y / (love.graphics.getHeight() / chunk.height))
        mouse = { x = chunkX, y = chunkY, button = mouse.button }
    end
end

function love.mousereleased(x, y, button, istouch)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        mouse.button = ""
    end
end

function love.draw(dt)
    -- clear color
    love.graphics.clear(0.07, 0.13, 0.17, 1.0)

    myQuad:render(0, 0)
    drawParticleMenu()
    imgui.Render();

    -- Print a circunference around the mouse
    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()

    local drawCircleSize = brush_size * (love.graphics.getWidth() / chunk.width)
    love.graphics.circle("line", mouseX, mouseY, drawCircleSize)

    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS() .. " GC: " .. gcinfo()), 10, 10)
end

function love.filedropped(file)
    -- Only run if the file is a lua file
    if file:getExtension() == "lua" then
        print("Running file: " .. file:getFilename())
        local fileRunner = require "fileRunner"
        fileRunner(file)
    else
        -- Show an error message as a popup (later I should make this a toast)
        local message = "The file you dropped is not a lua file"
        love.window.showMessageBox("Error", message, "error")
    end
end
