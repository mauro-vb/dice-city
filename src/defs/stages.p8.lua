-- stage 0 is the opening shop (no fight); each row after it is enemy,
-- reward, story; the last stage is the boss. what the shop offers: gen_offers
-- story: the comic caption boxes shown before the fight (placement), "/"
-- between boxes, \n between lines (up to 24 characters), all lowercase (the
-- regular font; uppercase letters would be the small puny font). no "," ";"
-- or "|"
stages = {[0] = {reward = 0}}
for r in all(split2d"enemy1,5,dice city.\nwhere every street\nis a gamble./fresh off the bus...\nand a tourist is\nalready in your way.|enemy2,6,One last pint.\nlast call was\nhours ago./someone at the bar\nis seeing double.|enemy3,7,there it is.\nthe casino./this is what\nyou came for./a bouncer blocks\nthe door.|enemy4,8,the card tables.\ncards on the table...\ndice in the air./a gambler eyes\nyour bag of dice.|enemy5,9,an unassuming old lady\nwaves at you from\nthe slot machines.|enemy6,10,the cashier cage.\nyour luck was on loan\nall along./time to pay it back.|enemy7,0,the top floor.\na man in a gold suit\nsteps out of the dark./the owner. the house\nalways wins... tonight\nit rolls against you.") do
	add(stages, {enemy = _ENV[r[1]], reward = r[2], story = r[3]})
end
stages[#stages].boss = true
