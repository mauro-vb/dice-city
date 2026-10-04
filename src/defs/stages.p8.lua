-- stage 0 is the opening shop (no fight); each row after it is enemy,
-- reward, story; the last stage is the boss. what the shop offers: gen_offers
-- story: the comic caption boxes shown before the fight (placement), "/"
-- between boxes, \n between lines (up to 24 characters), case swapped like
-- the names. no "," ";" or "|"
stages = {[0] = {reward = 0}}
for r in all(split2d"enemy1,2,dICE cITY.\nwHERE EVERY STREET\nIS A GAMBLE./fRESH OFF THE BUS...\nAND A TOURIST IS\nALREADY IN YOUR WAY.|enemy2,2,tHE lUCKY pINT.\nlAST CALL WAS\nHOURS AGO./sOMEONE AT THE BAR\nIS SEEING DOUBLE.|enemy3,3,cLUB sNAKE eYES.\ntHE WAY UP THE CITY\nGOES THROUGH THIS DOOR.|enemy4,3,tHE BACK ROOM.\ncARDS ON THE TABLE...\nDICE IN THE AIR./a GAMBLER EYES\nYOUR BAG OF DICE.|enemy5,4,cITY pARK.\naN OLD MAN IS FEEDING\nTHE PIGEONS... DICE?|enemy6,4,pAWN sHOP aLLEY.\nyOUR LUCK WAS ON LOAN\nALL ALONG./tIME TO PAY IT BACK.|enemy7,0,tHE cASINO.\ntOP FLOOR./tHE hOUSE ALWAYS\nWINS. tONIGHT IT\nROLLS AGAINST YOU.") do
	add(stages, {enemy = _ENV[r[1]], reward = r[2], story = r[3]})
end
stages[#stages].boss = true
