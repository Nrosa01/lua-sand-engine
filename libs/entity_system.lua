---@alias entity table -- The entity table, contains all the functions that are called by the entity system.
---@alias file any -- The file table, contains all the functions that are called by the entity system.

---@class entity_system
---@field entities table<number, entity> -- The table that stores all the entities in the system.
---@field add_entity fun(self: entity_system, entity: entity) -- Adds an entity to the entity system.
---@field remove_entity fun(self: entity_system, entity: entity) -- Removes an entity from the entity system.
---@field init fun(self: entity_system) -- Calls the init function of all the entities in the system.
---@field update fun(self: entity_system, dt: number) -- Calls the update function of all the entities in the system.
---@field draw fun(self: entity_system) -- Calls the draw function of all the entities in the system.
---@field key_pressed fun(self: entity_system, key: string, scancode: string, isrepeat: boolean) -- Calls the key_pressed function of all the entities in the system.
---@field key_released fun(self: entity_system, key: string) -- Calls the key_released function of all the entities in the system.
---@field mouse_pressed fun(self: entity_system, x: number, y: number, button: number, istouch: boolean, presses: number) -- Calls the mouse_pressed function of all the entities in the system.
---@field mouse_released fun(self: entity_system, x: number, y: number, button: number, istouch: boolean) -- Calls the mouse_released function of all the entities in the system.
---@field file_dropped fun(self: entity_system, file: file) -- Calls the file_dropped function of all the entities in the system.
---@field focus fun(self: entity_system, focused: boolean) -- Calls the focus function of all the entities in the system.
---@field resize fun(self: entity_system, w: number, h: number) -- Calls the resize function of all the entities in the system.
---@field mouse_moved fun(self: entity_system, x: number, y: number, dx: number, dy: number) -- Calls the mouse_moved function of all the entities in the system.
---@field wheel_moved fun(self: entity_system, x: number, y: number) -- Calls the wheel_moved function of all the entities in the system.
---@field quit fun(self: entity_system) -- Calls the quit function of all the entities in the system.
local entity_system = {}

entity_system.entities = {}

-- Adds an entity to the entity system (using array, entities are indexed by their id)
function entity_system:add_entity(entity)
    table.insert(self.entities, entity)
end

function entity_system:init()
    for i = 1, #self.entities do
        if self.entities[i].init then
            self.entities[i]:init()
        end
    end
end

-- Removes an entity from the entity system (linear search, not recommended)
function entity_system:remove_entity(entity)
    for i = 1, #self.entities do
        if self.entities[i] == entity then
            table.remove(self.entities, i)
            break
        end
    end
end

-- Updates all entities in the entity system
function entity_system:update(dt)
    for i = 1, #self.entities do
        if self.entities[i].update then
            self.entities[i]:update(dt)
        end
    end
end

-- Draws all entities in the entity system
function entity_system:draw()
    for i = 1, #self.entities do
        if self.entities[i].draw then
            self.entities[i]:draw()
        end
    end
end

-- Love callback: Called when a key is pressed
function entity_system:key_pressed(key, scancode, isrepeat)
    for i = 1, #self.entities do
        if self.entities[i].key_pressed then
            self.entities[i]:key_pressed(key, scancode, isrepeat)
        end
    end
end

-- Love callback: Called when a key is released
function entity_system:key_released(key)
    for i = 1, #self.entities do
        if self.entities[i].key_released then
            self.entities[i]:key_released(key)
        end
    end
end

-- Love callback: Called when the mouse is pressed
function entity_system:mouse_pressed(x, y, button, istouch, presses)
    for i = 1, #self.entities do
        if self.entities[i].mouse_pressed then
            self.entities[i]:mouse_pressed(x, y, button, istouch, presses)
        end
    end
end

-- Love callback: Called when the mouse is released
function entity_system:mouse_released(x, y, button, istouch, presses)
    for i = 1, #self.entities do
        if self.entities[i].mouse_released then
            self.entities[i]:mouse_released(x, y, button, istouch, presses)
        end
    end
end

-- Love callback: Called when a file is dropped onto the window
function entity_system:file_dropped(file)
    for i = 1, #self.entities do
        if self.entities[i].file_dropped then
            self.entities[i]:file_dropped(file)
        end
    end
end

-- Love callback: Called when the window receives focus
function entity_system:focus(focused)
    for i = 1, #self.entities do
        if self.entities[i].focus then
            self.entities[i]:focus(focused)
        end
    end
end

-- Love callback: Called when the window is resized
function entity_system:resize(w, h)
    for i = 1, #self.entities do
        if self.entities[i].resize then
            self.entities[i]:resize(w, h)
        end
    end
end

function entity_system:mouse_moved(x, y, dx, dy)
    for i = 1, #self.entities do
        if self.entities[i].mouse_moved then
            self.entities[i]:mouse_moved(x, y, dx, dy)
        end
    end
end

function entity_system:wheel_moved(x, y)
    for i = 1, #self.entities do
        if self.entities[i].wheel_moved then
            self.entities[i]:wheel_moved(x, y)
        end
    end
end

function entity_system:quit()
    for i = 1, #self.entities do
        if self.entities[i].quit then
            self.entities[i]:quit()
        end
    end
end

return entity_system
