
-- edge-triggered button check: true only on the frame b goes down.
-- unlike btnp() it never auto-repeats while held
--
-- usage: if pressed(❎) then jump() end -- call it every frame for that button

local prev_btn = {}

function pressed(b)
    local down = btn(b)
    local just = down and not prev_btn[b]
    prev_btn[b] = down
    return just
end
