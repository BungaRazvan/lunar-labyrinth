require('grid')



function drawTile(x,y)

    local isoX, isoY = gridToIso(x,y)

    local hw = TILE_SIZE
    local hh = TILE_SIZE/2

    love.graphics.polygon("line",
        isoX, isoY,
        isoX + hw, isoY + hh,
        isoX, isoY + hh*2,
        isoX - hw, isoY + hh
    )

end


function drawGears(gears)
    for _, g in ipairs(gears) do
        if not g.collected then
            local isoX, isoY = gridToIso(g.x, g.y)

            love.graphics.setColor(1, 0.8, 0)
            love.graphics.circle("fill", isoX, isoY + TILE_SIZE / 2, 6)
        end
    end
end


function drawPlayer(player)
    local isoX, isoY = gridToIso(player.x, player.y)

    love.graphics.setColor(0, 1, 0)
    love.graphics.circle('fill', isoX, isoY, TILE_SIZE / 2, 8)
    love.graphics.setColor(1, 1, 1)
end
