-- particle drawn from a spritesheet region (via src/utils/sprite.p8.lua's mspr)
-- instead of a plain shape -- good for pre-drawn fx like leaves, embers, coins
--
-- usage:
--   local leaf_spr = { 32, 8, 8, 8, 4, 4 } -- sx, sy, w, h, center-offset-x, center-offset-y
--   sprp({ x = 64, y = 64, sprarr = leaf_spr, maxage = 40, sy = 0.3 })

sprp = particle:extend({
    sprarr = { 0, 8, 16, 16, 8, 8 },
    flip_x = false,
    pdrw = function(_ENV)
        mspr(sprarr, x, y, flip_x)
    end
})
