local M = {}

local DIRS = {
    {1, 0},   -- right
    {-1, 0},  -- left
    {0, 1},   -- down
    {0, -1},  -- up
}


function reflectDirection(mirrorType, dx, dy)
    if mirrorType == "/" then
        return -dy, -dx
    elseif mirrorType == "\\" then
        return dy, dx
    end

    return dx, dy -- fallback (no change)
end

function getNextStates(x, y, dx, dy)
    local results = {}

    local nx = x + dx
    local ny = y + dy

    if not grid[ny] or not grid[ny][nx] then
        return results
    end

    local tile = grid[ny][nx]

    -- If it's a mirror → reflect direction
    if tile.type == "mirror" then
        local rdx, rdy = reflectDirection(tile.mirrorType, dx, dy)
        table.insert(results, {nx, ny, rdx, rdy})
    else
        table.insert(results, {nx, ny, dx, dy})
    end

    return results
end


function getNeighbors(x, y)
    return {
        { x + 1, y },
        { x - 1, y},
        { x, y + 1 },
        { x, y - 1 },
    }
end


function findPath(startX, startY, targetX, targetY)
    local queue = {}
    local visited = {}
    local parent = {}

    local function key(x, y, dx, dy)
        return x..","..y..","..dx..","..dy
    end

    -- Start in all 4 directions
    for _, d in ipairs(DIRS) do
        local dx, dy = d[1], d[2]
        table.insert(queue, {startX, startY, dx, dy})
        visited[key(startX, startY, dx, dy)] = true
    end

    while #queue > 0 do
        local node = table.remove(queue, 1)
        local x, y, dx, dy = node[1], node[2], node[3], node[4]

        if x == targetX and y == targetY then
            -- reconstruct path
            local path = {}
            local k = key(x, y, dx, dy)

            while k do
                local px, py = k:match("([^,]+),([^,]+),")
                table.insert(path, 1, {tonumber(px), tonumber(py)})
                k = parent[k]
            end

            return path
        end

        for _, nextState in ipairs(getNextStates(x, y, dx, dy)) do
            local nx, ny, ndx, ndy = unpack(nextState)
            local nk = key(nx, ny, ndx, ndy)

            if not visited[nk] then
                visited[nk] = true
                parent[nk] = key(x, y, dx, dy)
                table.insert(queue, {nx, ny, ndx, ndy})
            end
        end
    end

    return nil
end

function tilesConnect(tile1, tile2)
    if not tile1 or not tile2 then return false end

    local dx = tile1.x - tile2.x
    local dy = tile1.y - tile2.y
    if math.abs(dx) + math.abs(dy) == 1 then return true end

    for _, t in ipairs({tile1, tile2}) do
        if t.parent and t.parent.type == "mirror" then
            for _, linked in ipairs(t.parent.links or {}) do
                for _, lt in ipairs(linked.tiles) do
                    local tx, ty = linked.x + lt[1], linked.y + lt[2]
                    if (tx == tile1.x and ty == tile1.y) or (tx == tile2.x and ty == tile2.y) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function M.tryMoveToGear(gears, player)
    local queue = { {player.x, player.y} }
    local visited = {}
    local parent = {}

    local function key(x, y) return x..","..y end
    visited[key(player.x, player.y)] = true

    while #queue > 0 do
        local node = table.remove(queue, 1)
        local x, y = node[1], node[2]

        for _, gear in ipairs(gears) do
            if not gear.collected and x == gear.x and y == gear.y then
                -- reconstruct path
                local path = {}
                local k = key(x, y)
                while k do
                    local px, py = k:match("([^,]+),([^,]+)")
                    table.insert(path, 1, {tonumber(px), tonumber(py)})
                    k = parent[k]
                end
                player.path = path
                player.moving = true
                return
            end
        end

        -- check neighbors
        for _, dir in ipairs({{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}}) do
            local nx, ny = x + dir[1], y + dir[2]
            if grid[ny] and grid[ny][nx] then
                if tilesConnect(grid[y][x], grid[ny][nx]) then
                    local nk = key(nx, ny)
                    if not visited[nk] then
                        visited[nk] = true
                        parent[nk] = key(x, y)
                        table.insert(queue, {nx, ny})
                    end
                end
            end
        end
    end
end


return M