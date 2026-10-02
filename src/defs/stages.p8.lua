function stage_def(t)
	return merge({reward = 0, boss = false, offers = 3, pool = {}, always = {}}, t)
end

pool1 = {stairs, jackpot, gambler, chip, spike, solid}
pool3 = concat(pool1, {crit, anvil, pair, fang, brick})
pool4 = concat(pool3, {loaded, hero, crown})
pool5 = concat(pool4, {pillar, titan})

stages = {
	-- stage 0: the opening shop, no fight
	[0] = stage_def({pool = concat(pool1, {classic}), offers = 4}),
	stage_def({enemy = enemy1, reward = 2, pool = pool1}),
	stage_def({enemy = enemy2, reward = 2, pool = pool1}),
	stage_def({enemy = enemy3, reward = 3, pool = pool3, offers = 4}),
	stage_def({enemy = enemy4, reward = 3, pool = pool4, offers = 4}),
	stage_def({enemy = enemy5, reward = 4, pool = pool5, offers = 4}),
	stage_def({enemy = enemy6, boss = true}),
}
