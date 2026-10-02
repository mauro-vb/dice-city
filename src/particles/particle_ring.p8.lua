-- expanding ring outline -- good for shockwaves/explosions/impact rings.
-- drive its radius with `size` (e.g. incrsize, or tosize -- see particle.p8.lua)
--
-- usage: ringp({ x = 64, y = 64, c = 10, size = 2, incrsize = 1, maxage = 20, onend = "fade" })

ringp = particle:extend({
    thick = 2,
    pdrw = function(_ENV)
        if size < 1 then return end
        local ht = thick / 2
        for i = -ht, ht do
            circ(x + i, y, size, c)
            circ(x, y + i, size, c)
        end
    end
})
