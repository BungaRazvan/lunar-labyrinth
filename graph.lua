local M = {}

function getNeighbors(x, y)
    return {
        { x + 1, y },
        { x - 1, y},
        { x, y + 1 },
        { x, y - 1 },
    }
end


function findPath(startX, startY, targetX, targetY)
    local queue = { {startX, startY} }
    local visited = {}
    local parent = {}

    local function key(x, y) return x..","..y end
    visited[key(startX, startY)] = true

    while #queue > 0 do
        local node = table.remove(queue, 1)
        local x, y = node[1], node[2]

        if x == targetX and y == targetY then
            -- reconstruct path
            local path = {}
            local k = key(x, y)
            while k do
                local px, py = k:match("([^,]+),([^,]+)")
                table.insert(path, 1, {tonumber(px), tonumber(py)})
                k = parent[k]
            end
            return path
        end

        for _, n in ipairs(getNeighbors(x, y)) do
            local nx, ny = n[1], n[2]
            local nk = key(nx, ny)

            if not visited[nk] and grid[ny] and grid[ny][nx] then
                if tilesConnect(x, y, nx, ny) then
                    visited[nk] = true
                    parent[nk] = key(x, y)
                    table.insert(queue, {nx, ny})
                end
            end
        end
    end

    return nil
end

function tilesConnect(x1, y1, x2, y2)
    if not (grid[y1] and grid[y1][x1]) then return false end
    if not (grid[y2] and grid[y2][x2]) then return false end

    local dx = x2 - x1
    local dy = y2 - y1

    -- Adjacent cardinal directions OR diagonal for mirrors
    if math.abs(dx) + math.abs(dy) == 1 then
        return true -- normal neighbor
    end

    -- diagonal (L-connect) only if one is a mirror
    local tile1 = grid[y1][x1]
    local tile2 = grid[y2][x2]
    if tile1.parent and tile1.parent.type == "mirror" or
       tile2.parent and tile2.parent.type == "mirror" then
        if math.abs(dx) == 1 and math.abs(dy) == 1 then
            return true
        end
    end

    return false
end

function M.tryMoveToGear(gears, player)

    for _, g in ipairs(gears) do
        if not g.collected then
            local path = findPath(player.x, player.y, g.x, g.y)

            if path then
                player.path = path
                player.moving = true
                return
            end
        end
    end
end


return M