local imgui = require "imgui"
local beholder = require "beholder"
local EVENTS = require "src.core.observable_events"

local particle_menu = {}
-- particle_menu.__index = particle_menu
particle_menu.texts = {}
particle_menu.normalized_colors = {}
particle_menu.current_particle = 2

local windows_title = "Material selector"
local window_flags = { "ImGuiWindowFlags_AlwaysAutoResize" }

beholder.observe(EVENTS.MOD_ADDED, function()
    particle_menu:init()
end)

function particle_menu:init()
    local converter = 1.0 / 255.0
    self.texts = {}
    self.normalized_colors = {}

    local count = ParticleDefinitionsHandler:getRegisteredParticlesCount()

    for i = 1, count do
        local data = ParticleDefinitionsHandler:getParticleData(i)

        table.insert(self.texts, data.text_id .. "Color")
        table.insert(self.normalized_colors, { data.color.r * converter, data.color.g * converter,
            data.color.b * converter, data.color.a * converter })
    end
end

function particle_menu:draw()
    local count = ParticleDefinitionsHandler:getRegisteredParticlesCount()

    imgui.Begin(windows_title, true, window_flags);

    for i = 1, count do
        local data = ParticleDefinitionsHandler:getParticleData(i)

        if imgui.Selectable(data.text_id, self.current_particle == i) then
            self.current_particle = i
            beholder.trigger(EVENTS.CURRENT_PARTICLE_CHANGED, i)
        end
        imgui.SameLine()
        imgui.ColorButton(self.texts[i], self.normalized_colors[i][1], self.normalized_colors[i][2],
            self.normalized_colors[i][3], self.normalized_colors[i][4])
    end

    imgui.End()
end

function particle_menu:key_pressed(key, scancode, isrepeat)
    local pressedChar = string.lower(key)
    local startIdx = particle_menu.current_particle
    local found = false

    repeat
        startIdx = (startIdx % ParticleDefinitionsHandler:getRegisteredParticlesCount()) + 1
        local data = ParticleDefinitionsHandler:getParticleData(startIdx)
        local dataChar = string.lower(data.text_id:sub(1, 1))

        if dataChar == pressedChar then
            self.current_particle = startIdx
            beholder.trigger(EVENTS.CURRENT_PARTICLE_CHANGED, startIdx)
            found = true
            break
        end
    until startIdx == self.current_particle

    if not found then
        -- No particle found, we could play a sound or something here idk
    end
end

return particle_menu
