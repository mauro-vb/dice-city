-- shop items that aren't dice (no faces); economy applies them
-- inv = goes into the inventory (stacks per slot) and is used from there
-- aim = used on a die you pick (scenes ask for the die first), in these
-- placement phases: a reroll after rolling, a rig before
-- col = an enchantment: used on a die before the roll, it becomes that die's
-- d.ench (one per die, a new one replaces it) and colours its body. its
-- name starts with the same colour as a p8scii code (\f + hex digit)
--   greedy  unused, it pays double its roll
--   grower  placed in a fight, its lowest face goes up 1 for good
--   wild    the one die you can still move after the roll
--   glass   rolls double; 1 in 4 breaks when the fight starts
defs("id,name,price,info,inv,aim,col", "potion,beer,3,heals 5 hp,1|bomb,bomb,6,10 damage (in a fight),1|token,reroll,3,reroll a die you rolled,1,rolled|double,double,4,copy a placed die (1 fight),1,place rolled|rig,rig,4,+2 to a random face,1,place|greedy,\fagreedy,4,unused: pays 2x roll,1,place,10|grower,\fbgrower,4,placed: low face +1,1,place,11|wild,\fewild,4,move it after the roll,1,place,14|glass,\fcglass,3,2x roll (1/4 breaks),1,place,12")
item_kinds = names"potion,bomb,token,double,rig,greedy,grower,wild,glass"
