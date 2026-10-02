-- filled ball particle. above size 3 it gets a 1px rim in c's high nibble
-- (fillp trick: c = 0x7c is a blue ball with a white rim, plain c = 8 gets a
-- black rim). shine = true adds a highlight glint
--
-- usage: ballp({ x = 64, y = 64, c = 14, size = 8, maxage = 6, shine = true })

ballp = particle:extend({
    shine = false,
    pdrw = function(_ENV)
        local r = size / 2
        if size > 3 then
            fillp(0xffff)
            circfill(x, y, r, c)
            fillp()
        end
        circfill(x, y, r - 1, c)
        if shine and size > 4 then
            line(x - r + 2, y - r + 1, x, y - r + 1, 15)
            line(x - r + 1, y - r + 2, x + r - size / 1.5, y - r + 2, 15)
        end
    end
})
