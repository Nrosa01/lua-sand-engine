local Particle = require("Particle")

local N = 400*400
local img = create2darray(N, N)

print("Test")

for x=0,N-1 do
  for y=0,N-1 do
      print(x, y, img[x][y].type)
  end
end