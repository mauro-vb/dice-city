-- headless test harness, included first by tests/run.p8 (make test)
--
-- locals here are prefixed h_: every #include shares one chunk, so a
-- plain `local held` would shadow game fields like focus.held
--
-- usage (tests/test_*.lua):
--   test("player jumps", function()
--       boot()                             -- fresh _init()
--       hold(❎); step(2); release(❎)      -- fake input, run 2 frames
--       check(hero.dy < 0, "should rise")  -- assert
--       snap("jump")                       -- -> tests/snaps/jump.png
--   end)

reload(0x0, 0x0, 0x4300, "../cart.p8")

local h_held, h_prev = {}, {}

function btn(b) return h_held[b] or false end
function btnp(b) return h_held[b] and not h_prev[b] end

function hold(b) h_held[b] = true end
function release(b) h_held[b] = nil end

-- fake mouse: stat(32/33/34) read these instead of the real mouse
-- usage: mouse(40, 60, 1) -- move to 40,60 with the left button down
local h_mx, h_my, h_mb = 0, 0, 0
local h_stat = stat
function stat(n)
    if n == 32 then return h_mx end
    if n == 33 then return h_my end
    if n == 34 then return h_mb end
    return h_stat(n)
end
function mouse(x, y, b) h_mx, h_my, h_mb = flr(x), flr(y), b or 0 end

function step(n)
    for _ = 1, n or 1 do
        _update60()
        _draw()
        for b = 0, 5 do h_prev[b] = h_held[b] end
    end
end

-- fresh game: scene.load skips re-init of the current scene, so clear it;
-- pending tweens from an earlier test are dropped too
function boot()
    scene.current = nil
    tween = ptween()
    srand(42) -- the game seeds randomly; tests stay repeatable
    _init()
end

-- prints the screen + display palette as one "snap <name> <hex>" log line
-- (tests/snap.py turns those into tests/snaps/<name>.png)
function snap(name)
    local s = ""
    for a = 0x5f10, 0x5f1f do s ..= sub(tostr(@a, true), 5, 6) end
    for a = 0x6000, 0x7fff do s ..= sub(tostr(@a, true), 5, 6) end
    printh("snap " .. name .. " " .. s)
end

function check(cond, msg)
    assert(cond, msg or "check failed")
end

-- make test runs one test per cart, so a test reports its own result
function test(name, fn)
    h_held, h_prev = {}, {}
    local ok, err = coresume(cocreate(fn))
    if not ok then printh("FAIL " .. name .. ": " .. tostr(err)) end
    printh(ok and "ok 1/1" or "ok 0/1")
end

function test_summary()
    _init, _update60, _draw = nil
end
