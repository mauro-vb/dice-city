-- palette setup hook -- call once from _init()
--
-- usage: add {old_color, new_color} pairs to cmap below to remap colors
-- everywhere, e.g. cmap = { {8, 14} } turns color 8 (red) into 14 (pink)
function color_settings()
    palt(14, false)  -- color 0 (black) is opaque
    palt(4, true)   -- color 4 becomes the transparent color instead
    poke(0x5f2e, 1) -- persist the palette across screen updates
    local cmap = {

    }
    for c in all(cmap) do
        pal(c[1], c[2], 1)
    end
end
