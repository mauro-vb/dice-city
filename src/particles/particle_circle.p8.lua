-- filled circle particle
--
-- usage: circlep({ x = 64, y = 64, c = 8, size = 6, maxage = 20, onend = "fade" })

circlep = particle:extend({
    pdrw = function(_ENV)
        circfill(x, y, size / 2, c)
    end
})
