-- thin streak/spark particle -- draws a line trailing behind its (sx, sy)
-- motion, scaled by size. good for hit sparks, speed lines, embers
--
-- usage: sparkp({ x = 64, y = 64, c = 10, size = 3, sx = 1, sy = -1, maxage = 10, onend = "fade" })

sparkp = particle:extend({
    size = 1,
    pdrw = function(_ENV)
        line(x, y, x - (sx or 0) * size, y - (sy or 0) * size, c)
    end
})
