-- mouse: enabled here; main's _update60 sets mb (left button down: 1, else 0)
-- and pmb (mb on the last frame), so mb > pmb is a click, mb < pmb a release.
-- the position is stat(32), stat(33) (focus reads it)

poke(0x5f2d, 1) -- enable mouse input
mb = 0
