-- mouse cursor + button state tracker
--
-- usage:
--   cursor:upd()                 -- call every frame, in _update()
--   cursor.x, cursor.y           -- current mouse position
--   cursor:just_pressed(0x1)     -- left button pressed this frame
--   cursor:is_released(0x1)      -- left button released this frame
--   spr(32, cursor.x, cursor.y)  -- draw your own cursor sprite in _draw()

poke(0x5f2d, 1) -- enable mouse input

cursor = {
    x = 0,
    y = 0,
    _btn_prev = 0,
    _btn_curr = 0,

    upd = function(self)
        self.x = stat(32)
        self.y = stat(33)
        self._btn_prev = self._btn_curr
        self._btn_curr = stat(34)
    end,


    -- true only on the frame the button was first pressed
    just_pressed = function(self, btn)
        btn = btn or 0x1
        return (self._btn_curr & btn) ~= 0
            and (self._btn_prev & btn) == 0
    end,

    -- true only on the frame the button was released
    is_released = function(self, btn)
        btn = btn or 0x1
        return (self._btn_curr & btn) == 0
            and (self._btn_prev & btn) ~= 0
    end,
}
