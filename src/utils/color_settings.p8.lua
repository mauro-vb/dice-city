-- background colour: screens, unlit buttons, tooltip and result boxes
bg = 0
-- dark grey: outlines, empty bars, dim text, lines, lit button fill
dark = 5

-- palette setup hook -- call once from _init()
-- to remap a color everywhere add pal(old, new, 1), e.g. pal(8, 14, 1) turns
-- red into pink (the empty cmap loop that did this is in git)
function color_settings()
    palt(0, false)  -- color 0 (black) is opaque
    palt(11, true)   -- color 11 becomes the transparent color instead
    pal(1, 129, 1)
    --pal(8, 131, 1)
    --pal(2, 33, 1)

    poke(0x5f2e, 1) -- persist the palette across screen updates
    -- screen palette: slot 0 (black: background, pips, outlines) shows as
    -- extended colour 129 (navy). any slot can take 128-143 this way
end
