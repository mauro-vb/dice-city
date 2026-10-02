-- example test -- see tests/harness.lua for boot/step/hold/release/check/snap
test("boots into the first scene", function()
    boot()
    step(5)
    check(scene.current == main_scene)
    snap("boot")
end)
