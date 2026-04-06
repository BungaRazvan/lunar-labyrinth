require("grid")
require('tiles')

local P = require('platforms')

GRID_SIZE = 15
TILE_SIZE = 30
TRANSLATE_OFFSEX = 450
TRANSLATE_OFFSEY = 120
ROTATE_SPEED = 6


local selectedPlatform = nil

local platforms = {
    P.instantiatePlatform(P.sPlatformX, 9, 4),
    -- P.instantiatePlatform(P.sPlatformY, 9, 4),
    P.instantiatePlatform(P.lPlatform, 3, 4),
    P.instantiatePlatform(P.mirrorPlatform, 6, 4),
}

local gears = {
    {x = 6, y = 4, collected = false},
    {x = 8, y = 5, collected = false}
}



function love.load()
    love.window.setMode(900, 700)

    initGrid(GRID_SIZE)

    for _,p in ipairs(platforms) do
        P.placePlatformsOnGrid(p)
    end

end


function love.update(dt)
    for _, p in ipairs(platforms) do
        if p.rotating then

            -- Update animation timer
            p.animationTime = p.animationTime + dt
            local t = math.min(p.animationTime / p.animationDuration, 1)

            -- Lerp tiles between start and target
            for i = 1, #p.tiles do
                p.tiles[i][1] = p.startTiles[i][1] + (p.targetTiles[i][1] - p.startTiles[i][1]) * t
                p.tiles[i][2] = p.startTiles[i][2] + (p.targetTiles[i][2] - p.startTiles[i][2]) * t
            end

            -- Finish animation
            if t >= 1 then
                p.rotating = false
                -- Snap to final positions to avoid floating point errors
                for i = 1, #p.tiles do
                    p.tiles[i][1] = p.targetTiles[i][1]
                    p.tiles[i][2] = p.targetTiles[i][2]
                end

                -- Rebuild grid for collision
                initGrid(GRID_SIZE)
                for _, p2 in ipairs(platforms) do
                    P.placePlatformsOnGrid(p2)
                end
            end
        end
    end
end


function love.draw()
    love.graphics.translate(TRANSLATE_OFFSEX, TRANSLATE_OFFSEY)

    for y = 1, GRID_SIZE do
        for x = 1, GRID_SIZE do
            drawTile(x, y)
        end
    end

    for _, p in ipairs(platforms) do
        P.drawPlatform(p)
    end

    drawGears(gears)
end


function love.mousereleased(mx, my, button)
    selectedPlatform = nil
end

function love.mousepressed(mx, my, button)

    mx = mx - TRANSLATE_OFFSEX
    my = my - TRANSLATE_OFFSEY

    for i = #platforms, 1, -1 do
        local p = platforms[i]

        for _, t in ipairs(p.tiles) do

            local gx = p.x + t[1]
            local gy = p.y + t[2]

            local isoX, isoY = gridToIso(gx, gy)

            local hw, hh = TILE_SIZE, TILE_SIZE / 2

            if mx > isoX - hw and mx < isoX + hw
            and my > isoY and my < isoY + hh * 2 then

                selectedPlatform = p
                selectedPlatform.grabTile = { x = t[1], y = t[2] }

                if selectedPlatform.action == 'rotate' then
                    local direction = selectedPlatform.direction == 'cw' and 'ccw' or 'cw'
                    P.rotatePlatform(selectedPlatform, direction, platforms)
                end

                return
            end
        end
    end
end


function love.mousemoved(mx, my, dx, dy)

    if not selectedPlatform then return end
    if not selectedPlatform.mutable then return end
    if selectedPlatform.action ~= "drag" then return end

    mx = mx - TRANSLATE_OFFSEX
    my = my - TRANSLATE_OFFSEY

    local gx, gy = isoToGrid(mx, my)
    local currX, currY = selectedPlatform.x, selectedPlatform.y
    local targetX = gx - selectedPlatform.grabTile.x
    local targetY = gy - selectedPlatform.grabTile.y

    -- clamp to grid
    targetX = math.max(1, math.min(GRID_SIZE - selectedPlatform.maxX, targetX))
    targetY = math.max(1, math.min(GRID_SIZE - selectedPlatform.maxY, targetY))

    -- step-by-step axis-locked movement
    if selectedPlatform.dragAxis == "x" then
        local step = (targetX > currX) and 1 or -1
        while currX ~= targetX do
            if P.canDrag(selectedPlatform, currX + step, currY, platforms) then
                currX = currX + step
            else break end
        end
        selectedPlatform.x = currX

    elseif selectedPlatform.dragAxis == "y" then
        local step = (targetY > currY) and 1 or -1
        while currY ~= targetY do
            if P.canDrag(selectedPlatform, currX, currY + step, platforms) then
                currY = currY + step
            else break end
        end
        selectedPlatform.y = currY
    end

    -- update grid
    initGrid(GRID_SIZE)
    for _, p in ipairs(platforms) do
        P.placePlatformsOnGrid(p)

        if p.mirror then
            P.updateMirrorConnections(p, platforms)
        end
    end
end