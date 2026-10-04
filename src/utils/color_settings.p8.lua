-- background colour: screens, unlit buttons, tooltip and result boxes
bg = 0
-- dark grey: outlines, empty bars, dim text, lines, lit button fill
dark = 5

-- palette setup hook -- call once from _init()
-- to remap a colour everywhere, change the first number of its row in fades
-- (src/oop/scene) and the steps after it: _draw sets the screen palette from
-- there every frame, so pal(old, new, 1) here would be overwritten. slot 1
-- shows extended colour 129 (navy); any slot can take 128-143 this way
function color_settings()
    palt(0, false)  -- color 0 (black) is opaque
    palt(11, true)   -- color 11 becomes the transparent color instead
    poke(0x5f2e, 1) -- persist the palette across screen updates
end
