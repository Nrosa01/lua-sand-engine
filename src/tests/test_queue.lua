-- Import the Queue class
local Queue = require("queue")

-- Test case 1: Test enqueue and dequeue operations
local queue = Queue:new()
queue:enqueue(1)
queue:enqueue(2)
queue:enqueue(3)
assert(queue:dequeue() == 1, "Test case 1 failed")
assert(queue:dequeue() == 2, "Test case 1 failed")
assert(queue:dequeue() == 3, "Test case 1 failed")

-- Test case 2: Test isEmpty function
local queue = Queue:new()
assert(queue:isEmpty() == true, "Test case 2 failed")
queue:enqueue(1)
assert(queue:isEmpty() == false, "Test case 2 failed")

-- Test case 3: Test size function
local queue = Queue:new()
assert(queue:size() == 0, "Test case 3 failed")
queue:enqueue(1)
queue:enqueue(2)
queue:enqueue(3)
assert(queue:size() == 3, "Test case 3 failed")

-- Test case 4: Test peek function
local queue = Queue:new()
queue:enqueue(1)
queue:enqueue(2)
queue:enqueue(3)
assert(queue:peek() == 1, "Test case 4 failed")
queue:dequeue()
assert(queue:peek() == 2, "Test case 4 failed")

-- Test case 5: Test clear function
local queue = Queue:new()
queue:enqueue(1)
queue:enqueue(2)
queue:enqueue(3)
queue:clear()
assert(queue:size() == 0, "Test case 5 failed")
assert(queue:isEmpty() == true, "Test case 5 failed")

print("Queue tests passed")
