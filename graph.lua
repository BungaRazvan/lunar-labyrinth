local M = {}

function M.getNeighbors(x, y)
    return {
        { x + 1, y },
        { x - 1, y},
        { x, y + 1 },
        { x, y - 1 },
    }
end


function M.findReachable(startX, startY)
    local visited = {}
    local queue = { { startX, startY } }

    visited[startX..","..startY] = true

    while #queue > 0 do
        local node = table.remove(queue, 1)
        local x, y = node[1], node[2]

        for _, n in ipairs(M.getNeighbors(x, y)) do
            local nx, ny = n[1], n[2]
            local key = nx..","..ny

            if not visited[key] then
                if grid[ny] and grid[ny][nx] then
                    visited[key] = true
                    table.insert(queue, { nx, ny })
                end
            end

        end
    end

    return visited
end


return M