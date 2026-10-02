-- floating text particle -- damage numbers, score popups, pickup labels
--
-- usage: textp({ x = 64, y = 64, c = 7, text = "+10", sy = -0.5, maxage = 30 })
-- ocol = "2" draws a 1px outline in that color (p8scii \^o)
-- (skip onend = "fade" here -- fade shrinks `size`, which plain print() ignores)

textp = particle:extend({
    text = "",
    pdrw = function(_ENV)
        print(ocol and "\^o" .. ocol .. "40" .. text or text, x, y, c)
    end
})
