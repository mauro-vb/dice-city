-- mouse cursor + button state tracker
--
-- usage:
--   cursor:upd()                 -- call every frame, in _update()
--   cursor.x, cursor.y           -- current mouse position
--   cursor:just_pressed()        -- left button pressed this frame
--   cursor:is_released()         -- left button released this frame
--   spr(32, cursor.x, cursor.y)  -- draw your own cursor sprite in _draw()

poke(0x5f2d, 1) -- enable mouse input

-- x, y and _btn_prev are set by upd before anything reads them
cursor = {
    _btn_curr = 0,

    upd = function(self)
        self.x = stat(32)
        self.y = stat(33)
        self._btn_prev = self._btn_curr
        self._btn_curr = stat(34)
    end,


    -- true only on the frame the button was first pressed
    just_pressed = function(self)
        return (self._btn_curr & 1) ~= 0
            and (self._btn_prev & 1) == 0
    end,

    -- true only on the frame the button was released
    is_released = function(self)
        return (self._btn_curr & 1) == 0
            and (self._btn_prev & 1) ~= 0
    end,
}
