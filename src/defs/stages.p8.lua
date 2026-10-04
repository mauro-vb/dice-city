-- stage 0 is the opening shop (no fight); each row after it is enemy,
-- reward; the last stage is the boss. what the shop offers: gen_offers
stages = {[0] = {reward = 0}}
for r in all(split2d"enemy1,2|enemy2,2|enemy3,3|enemy4,3|enemy5,4|enemy6,4|enemy7,0") do
	add(stages, {enemy = _ENV[r[1]], reward = r[2]})
end
stages[#stages].boss = true
