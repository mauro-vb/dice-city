-- filled oval particle -- independent x/y radii via sizex/sizey (size itself
-- is unused here; drive sizex/sizey directly, or tween them yourself)
--
-- usage: ovalp({ x = 64, y = 64, c = 12, sizex = 4, sizey = 2, maxage = 15 })

ovalp = particle:extend({
    sizex = 1,
    sizey = 2,
    border = false,
    pdrw = function(_ENV)
        if border then
            fillp(0xffff)
            ovalfill(x - sizex / 2 - 1, y - sizey / 2 - 1, x + sizex / 2 + 1, y + sizey / 2 + 1, c)
            fillp(0x0)
        end
        ovalfill(x - sizex / 2, y - sizey / 2, x + sizex / 2, y + sizey / 2, c)
    end
})
