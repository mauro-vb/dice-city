-- usage: lerp(0, 100, 0.5) -> 50
function lerp(a, b, t)
	return a + (b - a) * t
end
