-- write a hex pixel string (one char per pixel, row by row) into the spritesheet
-- usage: gfx_str(0, 64, 54, "eee0...") -- then sspr it like any sprite
-- (mspr / cycanim / frames lived here; removed for tokens, they're in git)
function gfx_str(x0, y0, w, s)
    for i = 1, #s do
        sset(x0 + (i - 1) % w, y0 + (i - 1) \ w, tonum("0x" .. s[i]))
    end
end
