-- stage 0 is the opening shop (dice only, no fight); each row after it is
-- enemy, reward, offers; the last stage is the boss. pool entries repeat to
-- weight them (items are 4 in 12 offers)
stages = {[0] = {pool = names"d6,d3", offers = 4, reward = 0}}
for r in all(split2d"enemy1,2,3|enemy2,2,3|enemy3,3,4|enemy4,3,4|enemy5,4,4|enemy6,0,0") do
	add(stages, {enemy = _ENV[r[1]], reward = r[2], offers = r[3], pool = names"d6,d6,d3,d3,d6g,d3p,d3pp,d8,potion,token,bomb,double,rig"})
end
stages[#stages].boss = true
