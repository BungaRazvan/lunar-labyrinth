require('grid')

local M = {}

M.lPlatform = {
    type = "platform",
    mutable = true,
    action = "rotate",
    color = {1,0.6,0.3},
    rotating = false,
    tiles = {
        {0,0},
        {1,0},
        {2,0},
        {0,1},
        {0,2}
    }
}

M.sPlatformX = {
    type = "platform",
    mutable = true,
    action = "drag",
    color = {1,1,0},
    dragAxis = 'x',
    tiles = {
        {0,0},
        {1,0},
        {2,0}
    }
}

M.sPlatformY = {
    type = "platform",
    mutable = true,
    action = "drag",
    color = {1,1,0},
    dragAxis = 'y',
    tiles = {
        {0,0},
        {0,1},
        {0,2}
    }
}

M.tPlatform = {
    type = "platform",
    mutable = true,
    color = {0,1,1},
    tiles = {
        {0,0},
        {1,0},
        {2,0},
        {1,1}
    }
}

M.mirrorPlatform = {
    type = "mirror",
    mutable = true,
    action = 'drag',
    dragAxis = 'y',
    tiles = { {0,0} },
    links = {},
    color = {0.7,0.8,1},
}

function M.placePlatformsOnGrid(platform)
    for _, t in ipairs(platform.tiles) do
        local gx = platform.x + t[1]
        local gy = platform.y + t[2]

       if grid[gy] and grid[gy][gx] then
            grid[gy][gx] = { parent = platform }
        end

    end
end

function M.drawPlatform(platform)

    local hw = TILE_SIZE
    local hh = TILE_SIZE / 2

    love.graphics.setColor(platform.color)

    for _, t in ipairs(platform.tiles) do
        local isoX, isoY = gridToIso(platform.x + t[1], platform.y + t[2])
        love.graphics.polygon(
            "fill",
            isoX,
            isoY,
            isoX + hw,
            isoY + hh,
            isoX,
            isoY + hh * 2,
            isoX - hw,
            isoY + hh
    )
    end

    love.graphics.setColor(1, 1, 1)

end


function M.instantiatePlatform(template, x, y)

    local p = {}

    -- copy everything except tiles
    for k,v in pairs(template) do
        if k ~= "tiles" then
            p[k] = v
        end
    end

    p.x, p.y = x, y
    p.maxX, p.maxY = 0, 0

    -- create NEW tiles table
    p.tiles = {}

    for i,t in ipairs(template.tiles) do
        p.tiles[i] = {t[1], t[2]}
        p.maxX = math.max(p.maxX, t[1])
        p.maxY = math.max(p.maxY, t[2])
    end

    return p
end


function getRotatedTiles(platform, direction)

    local newTiles = {}

    for _, t in ipairs(platform.tiles) do
        local x, y = t[1], t[2]

        if direction == "cw" then
            table.insert(newTiles, {y, -x})
        else
            table.insert(newTiles, {-y, x})
        end
    end

    return newTiles
end



function M.canDrag(platform, newX, newY, allPlatforms)

    local occupied = getOccupied(platform, allPlatforms)

    local checkX, checkY = newX, newY
    if platform.dragAxis == "x" then checkY = platform.y end
    if platform.dragAxis == "y" then checkX = platform.x end

    for _, t in ipairs(platform.tiles) do
        local tx, ty = checkX + t[1], checkY + t[2]
        if tx < 1 or tx > GRID_SIZE or ty < 1 or ty > GRID_SIZE then return false end
        if occupied[tx..","..ty] then return false end
    end

    return true, checkX, checkY
end


function getOccupied(platform, allPlatforms)
    local occupied = {}

    for _, p in ipairs(allPlatforms) do
        if p ~= platform then
            for _, t in ipairs(p.tiles) do
                local ox = p.x + t[1]
                local oy = p.y + t[2]
                occupied[ox..","..oy] = true
            end
        end

    end

    return occupied

end


function canRotate(platform, direction, allPlatforms)

    local rotatedTiles = getRotatedTiles(platform, direction)

    local occupied = getOccupied(platform, allPlatforms)

    for _, t in ipairs(rotatedTiles) do
        local tx = platform.x + t[1]
        local ty = platform.y + t[2]

        if tx < 1 or tx > GRID_SIZE or ty < 1 or ty > GRID_SIZE then
            return false
        end

        if occupied[tx..","..ty] then
            return false
        end
    end

    return true, rotatedTiles
end


function M.rotatePlatform(platform, direction, allPlatforms)

    if platform.rotating then return end

    local ok, newTiles = canRotate(platform, direction, allPlatforms)
    if not ok then return end

    -- store starting tiles
    platform.startTiles = {}
    for i, t in ipairs(platform.tiles) do
        platform.startTiles[i] = { t[1], t[2] }
    end

    -- use rotated tiles from canRotate
    platform.targetTiles = newTiles

    platform.animationTime = 0
    platform.animationDuration = 0.2
    platform.rotating = true

    if not platform.direction then return end
    platform.direction = direction

end


-- call this whenever mirror rotates or platform moves
function M.updateMirrorConnections(mirror, platforms)

    local x = mirror.x
    local y = mirror.y

    local left  = {x-1, y}
    local up    = {x, y-1}

    mirror.links = {}

    for _,p in ipairs(platforms) do
        for _,t in ipairs(p.tiles) do
            local tx = p.x + t[1]
            local ty = p.y + t[2]

            if (tx == left[1] and ty == left[2]) or
               (tx == up[1] and ty == up[2]) then
                table.insert(mirror.links, p)
            end
        end
    end
end

function M.checkGearCollection(reachable, gears)

    for _, g in ipairs(gears) do
        local key = g.x..","..g.y

        if reachable[key] then
            g.collected = true
        end
    end
end


return M