-- filled rectangle particle -- width/height scale independently via
-- iwidth/iheight * size, so a single `size` still drives easing/fade
--
-- usage: rectp({ x = 64, y = 64, c = 7, size = 4, iwidth = 2, iheight = 1, maxage = 10 })

rectp = particle:extend({
    iwidth = 2,
    iheight = 1,
    border = false,
    pinit = function(_ENV)
        width = iwidth * size
        height = iheight * size
    end,
    upd = function(_ENV)
        width = size * iwidth
        height = size * iheight
        dopart(_ENV)
    end,
    pdrw = function(_ENV)
        local w, h = width / 2, height / 2
        rectfill(x - w, y - h, x + w, y + h, c)
        if border then
            fillp(0xffff)
            rect(x - w, y - h, x + w, y + h, c)
            fillp(0x0)
        end
    end
})
