stage = game_object:extend({
	enemy = enemy1,
	reward = 5,
	boss = false,
	shop = {pool = {classic}, offers = 3, always = {}},
	items = {},
	init = function(_ENV)
		for i=1, shop.offers do
			items[i] = rnd(shop.pool)
		end
		for i=1, #shop.always do
			items[i] = shop.always[i]
		end
	end
})

stages = {
	stage:new(),
	stage:new({enemy = enemy2, boss = true})
}
