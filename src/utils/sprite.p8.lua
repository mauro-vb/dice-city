-- draw sprites from arbitrary (and larger-than-8x8) spritesheet regions
--
-- usage:
--   local icon = { 32, 0, 16, 16, 8, 8 } -- sx, sy, w, h, center-offset-x, center-offset-y
--   mspr(icon, 64, 64)                    -- draws centered on (64, 64)
--   mspr(icon, 64, 64, false, false, 20, 12) -- stretched to 20x12 (squash/stretch)
-- (cycanim / frames lived here too; removed while unused, they're in git)

function mspr(s, x, y, fx, fy, dw, dh)
    sspr(
        s[1], s[2],         -- spr coordinates
        s[3], s[4],         -- spr width and height
        x - s[5], y - s[6], -- center x center y
        dw or s[3], dh or s[4],
        fx, fy              -- flip x flip y
    )
end
