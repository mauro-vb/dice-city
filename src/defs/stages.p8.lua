-- stage 0 is the opening shop (no fight); each row after it is enemy,
-- reward, story; the last stage is the boss. what the shop offers: gen_offers
-- story: the comic caption boxes shown before the fight (placement), "/"
-- between boxes, \n between lines (up to 24 characters), all lowercase (the
-- regular font; uppercase letters would be the small puny font). no "," ";"
-- or "|"
stages = {[0] = {reward = 0}}
for r in all(split2d"enemy1,2,dice city.\nwhere every street\nis a gamble./fresh off the bus...\nand a tourist is\nalready in your way.|enemy2,2,the lucky pint.\nlast call was\nhours ago./someone at the bar\nis seeing double.|enemy3,3,club snake eyes.\nthe way up the city\ngoes through this door.|enemy4,3,the back room.\ncards on the table...\ndice in the air./a gambler eyes\nyour bag of dice.|enemy5,4,city park.\nan old man is feeding\nthe pigeons... dice?|enemy6,4,pawn shop alley.\nyour luck was on loan\nall along./time to pay it back.|enemy7,0,the casino.\ntop floor./the house always\nwins. tonight it\nrolls against you.") do
	add(stages, {enemy = _ENV[r[1]], reward = r[2], story = r[3]})
end
stages[#stages].boss = true
