-- draw sprites from arbitrary (and larger-than-8x8) spritesheet regions
--
-- usage:
--   local icon = { 32, 0, 16, 16, 8, 8 } -- sx, sy, w, h, center-offset-x, center-offset-y
--   mspr(icon, 64, 64)                    -- draws centered on (64, 64)
-- (cycanim / frames lived here too; removed while unused, they're in git)

function mspr(s, x, y)
    sspr(s[1], s[2], s[3], s[4], x - s[5], y - s[6])
end
