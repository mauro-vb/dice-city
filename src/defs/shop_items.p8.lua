-- shop items that aren't dice (no faces); economy applies them
-- inv = goes into the inventory (stacks per slot) and is used from there
-- aim = used on a die you pick (scenes ask for the die first), in these
-- placement phases: a reroll after rolling, a rig before
defs("id,name,price,info,inv,aim", "potion,beer,3,heals 5 hp,1|bomb,bomb,4,4 damage (in a fight),1|token,reroll,3,reroll a die you rolled,1,rolled|double,double,4,copy a placed die (1 fight),1,place rolled|rig,rig,4,+2 to a random face,1,place")
item_kinds = names"potion,bomb,token,double,rig"
