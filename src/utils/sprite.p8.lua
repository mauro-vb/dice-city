-- draw sprites from arbitrary (and larger-than-8x8) spritesheet regions,
-- and cycle through animation-frame arrays
--
-- usage:
--   local icon = { 32, 0, 16, 16, 8, 8 } -- sx, sy, w, h, center-offset-x, center-offset-y
--   mspr(icon, 64, 64)                    -- draws centered on (64, 64)
--   mspr(icon, 64, 64, false, false, 20, 12) -- stretched to 20x12 (squash/stretch)
--   cycanim(t, { 1, 2, 3, 2 }, 4)         -- cycles frame indices, 4 game-frames per step
--   frames(1, 5)                          -- { myspr[1], ..., myspr[5] }

function mspr(s, x, y, fx, fy, dw, dh)
    sspr(
        s[1], s[2],         -- spr coordinates
        s[3], s[4],         -- spr width and height
        x - s[5], y - s[6], -- center x center y
        dw or s[3], dh or s[4],
        fx, fy              -- flip x flip y
    )
end

function cycanim(age, arr, spd, inv)
    local spd = spd or 1
    local t = age \ spd
    if inv then t = #arr - 1 - t % #arr
    else t = t % #arr
    end
    return arr[t + 1]
end

function frames(first, last)
    local arr = {}
    for i = first, last do
        add(arr, myspr[i])
    end
    return arr
end

-- write a hex pixel string (one char per pixel, row by row) into the spritesheet
-- usage: gfx_str(0, 64, 54, "eee0...") -- then sspr / mspr it like any sprite
function gfx_str(x0, y0, w, s)
    for i = 1, #s do
        sset(x0 + (i - 1) % w, y0 + (i - 1) \ w, tonum("0x" .. s[i]))
    end
end
