-- pool entries repeat to weight them: items are about 1 in 3 offers
function stage_def(t)
	return merge({reward = 0, boss = false, offers = 3, pool = {d6, d6, d3, d3, potion, token}, always = {}}, t)
end

stages = {
	-- stage 0: the opening shop, no fight, dice only
	[0] = stage_def({pool = {d6, d3}, offers = 4}),
	stage_def({enemy = enemy1, reward = 2}),
	stage_def({enemy = enemy2, reward = 2}),
	stage_def({enemy = enemy3, reward = 3, offers = 4}),
	stage_def({enemy = enemy4, reward = 3, offers = 4}),
	stage_def({enemy = enemy5, reward = 4, offers = 4}),
	stage_def({enemy = enemy6, boss = true}),
}
