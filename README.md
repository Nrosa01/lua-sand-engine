# Lua sand engine

https://github.com/user-attachments/assets/dd72b0c5-fc85-4bdb-b160-5fefe385b639

https://github.com/user-attachments/assets/d7213d0f-8055-4a77-9bef-43eb4c9bdabc

Simple falling sand simulation done in the LÖVE engine. 

Features:
- Multithreaded support optimized for maximum performance
  - Takes into account the amount of cores in your machine
  - Takes into account the size of the simulation
- Drag and drop script system
  - You can create your own particles as a lua script and simple drag it into the game windows to get it loaded
- Powerful script system
  - The API allows you to create a great variety of behaviours the exact way you want. See the API reference below
  - Check example script [script](./libs/plant.lua)
  - A [game of life implementation](./libs/gol.lua) is provided too
- Convert images to particles!
  - Drag and drop ANY image to the canvas and enjoy.
 
Controls:
  - Click to add particles or select material in the material windows
  - Keyboard keys to select materials based on their initial
  - Space toggles the simulation update aka pause button

# Documentation

## 1. Defining a Particle

To define a particle, copy the following template and adapt it to your needs:

```lua
addParticle(
    "MyParticle",                            -- Particle name
    { r = 255, g = 255, b = 255, a = 255 },  -- RGBA color
    function(api)                            -- Behaviour
        -- Particle logic here
    end
)
```

* The particle name must be a string.
* Color values range from 0 to 255.

Particle IDs are automatically generated from the name and exposed as `ParticleType.MY_PARTICLE`.

There is always a special particle representing the absence of a particle: `ParticleType.EMPTY`.

## 2. Particle API

Inside the behavior function, the following API methods are available. All methods are called as `api:method()`.

### Neighbour Access

```lua
api:get_neighbours()
```

Returns an array of direction objects with `x` and `y` components. Useful to iterate over adjacent particles:

```lua
for _, direction in ipairs(api:get_neighbours()) do
    if api:getParticleType(direction.x, direction.y) == ParticleType.TYPE then
        -- Do something
    end
end
```

### Particle Manipulation

```lua
api:setNewParticleById(x, y, id)
```

Replaces the particle at relative position `(x, y)` with the given particle ID.

* `x > 0` right, `x < 0` left
* `y > 0` up, `y < 0` down

```lua
api:swap(x, y)
```

Swaps the current particle with the particle at `(x, y)`.

### Queries

```lua
api:isEmpty(x, y)
```

Returns `true` if the target position is empty.

```lua
api:getParticleType(x, y)
```

Returns the particle ID at `(x, y)`.

```lua
api:check_neighbour_multi(x, y, id_array)
```

Returns `true` if the particle at `(x, y)` matches any ID in `id_array`.

## 3. Complete Particle Example

The following particle moves downward if the cell below is empty or air:

```lua
addParticle(
    "GoDown",
    { r = 255, g = 0, b = 255, a = 255 },
    function(api)
        local dirY = -1
        local id_array = { ParticleType.EMPTY, ParticleType.AIR }

        if api:check_neighbour_multi(0, dirY, id_array) then
            api:swap(0, dirY)
        end
    end
)
```

