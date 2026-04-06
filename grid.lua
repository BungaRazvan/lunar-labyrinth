grid = {}

function initGrid(GRID_SIZE)
    for y = 1, GRID_SIZE do
        grid[y] = {}

        for x = 1, GRID_SIZE do
            grid[y][x] = {
                type = "empty"
            }
        end
    end
end

function gridToIso(x, y)
    local isoX = (x - y) * TILE_SIZE
    local isoY = (x + y) * TILE_SIZE / 2

    return isoX, isoY
end

function isoToGrid(x, y)

    local gx = (x / TILE_SIZE + y / (TILE_SIZE/2)) / 2
    local gy = (y / (TILE_SIZE/2) - x / TILE_SIZE) / 2

    gx = math.floor(gx + 0.5)
    gy = math.floor(gy + 0.5)

    return gx, gy
end

function screenToGrid(mx, my)
    mx = mx - 450
    my = my - 120

    local x = math.floor((mx / TILE_SIZE + my / (TILE_SIZE / 2)) / 2)
    local y = math.floor((my / (TILE_SIZE/2) - mx / TILE_SIZE) / 2)

    return x, y
end

