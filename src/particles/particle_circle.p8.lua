-- filled circle particle
--
-- usage: circlep({ x = 64, y = 64, c = 8, size = 6, maxage = 20, onend = "fade" })

circlep = particle:extend({
    pdrw = function(_ENV)
        circfill(x, y, size / 2, c)
    end
})

-- hit spark: 8 spikes out from a white core, white then yellow then orange,
-- growing by incrsize
sparkp = particle:extend({
    pdrw = function(_ENV)
        for i = 1, 8 do
            local cx, cy = cos(i / 8) * size, sin(i / 8) * size
            line(x + cx / 3, y + cy / 3, x + cx, y + cy, age < 2 and 7 or age < 4 and 10 or 9)
        end
        circfill(x, y, size / 4, 7)
    end
})
