-- headless test harness, included first by tests/run.p8 (make test)
--
-- usage (tests/test_*.lua):
--   test("player jumps", function()
--       boot()                             -- fresh _init()
--       hold(❎); step(2); release(❎)      -- fake input, run 2 frames
--       check(hero.dy < 0, "should rise")  -- assert
--       snap("jump")                       -- -> tests/snaps/jump.png
--   end)

reload(0x0, 0x0, 0x4300, "../cart.p8")

local held, prev = {}, {}
local passed, failures = 0, {}

function btn(b) return held[b] or false end
function btnp(b) return held[b] and not prev[b] end

function hold(b) held[b] = true end
function release(b) held[b] = nil end

function step(n)
    for _ = 1, n or 1 do
        (_update60 or _update)()
        _draw()
        for b = 0, 5 do prev[b] = held[b] end
    end
end

-- fresh game: scene.load skips re-init of the current scene, so clear it;
-- pending tweens from an earlier test are dropped too
function boot()
    scene.current = nil
    tween = ptween()
    freeze_frames = 0
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

function test(name, fn)
    held, prev = {}, {}
    local co = cocreate(fn)
    local ok, err = coresume(co)
    if ok then
        passed += 1
    else
        add(failures, name .. ": " .. tostr(err))
    end
end

function test_summary()
    for f in all(failures) do printh("FAIL " .. f) end
    printh("ok " .. passed .. "/" .. (passed + #failures))
    _init, _update, _update60, _draw = nil
end
