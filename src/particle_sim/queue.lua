
-- Define the Queue class
---@class Queue
---@field data table
---@field front number
---@field back number
---@field isEmpty function
---@field size function
---@field enqueue function
---@field dequeue function
---@field peek function
---@field clear function
Queue = {}

-- Create a new instance of the Queue class
function Queue:new()
    local obj = {
        data = {},
        front = 1,
        back = 0
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- Check if the queue is empty
function Queue:isEmpty()
    return self.front > self.back
end

-- Get the size of the queue
function Queue:size()
    return self.back - self.front + 1
end

-- Enqueue an element to the back of the queue
function Queue:enqueue(element)
    self.back = self.back + 1
    self.data[self.back] = element
end

-- Dequeue an element from the front of the queue
function Queue:dequeue()
    if self:isEmpty() then
        return nil
    end
    local element = self.data[self.front]
    self.data[self.front] = nil
    self.front = self.front + 1
    return element
end

-- Get the element at the front of the queue without removing it
function Queue:peek()
    if self:isEmpty() then
        return nil
    end
    return self.data[self.front]
end

-- Clear the queue
function Queue:clear()
    self.data = {}
    self.front = 1
    self.back = 0
end

return Queue
