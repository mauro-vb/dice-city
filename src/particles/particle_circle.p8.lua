-- filled circle particle
--
-- usage: circlep({ x = 64, y = 64, c = 8, size = 6, maxage = 20, onend = "fade" })
-- set border = true for a 1px outline (uses PICO-8's dither pattern, not a color)

function drw_circle(_ENV)
    if border then
        fillp(0xffff)
        circfill(x, y, size / 2 + 1, c)
        fillp(0x0)
    end
    circfill(x, y, size / 2, c)
end

circlep = particle:extend({
    size = 1,
    border = false,
    pdrw = drw_circle
})
