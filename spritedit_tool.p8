pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- tool by lazy devs
function _init()
	palt(0, false)
	palt(14, true)
 --- customize here ---
 #include data/myspr.txt
 file="data/myspr.txt"
 arrname="myspr"
 data=myspr
 --reload(0x0,0x0,0x2000,"cart.p8")
 ----------------------

 debug={}
 msg={}

 _drw=draw_list
 _upd=update_list

 menuitem(1,"export",export)


 curx=1
 cury=1
 scrolly=0
 scrollx=0

 poke(0x5f2d, 1)
end

function _draw()
 _drw()

 if #msg>0 then
  bgprint(msg[1].txt,64-#msg[1].txt*2,80,14)
  msg[1].t-=1
  if msg[1].t<=0 then
   deli(msg,1)
  end
 end

 -- debug --
 cursor(4,4)
 color(8)
 for txt in all(debug) do
  print(txt)
 end
end

function _update60()
 dokeys()
 mscroll=stat(36)

 _upd()
end

function dokeys()
 if stat(30) then
  key=stat(31)
  if key=="p" then
   poke(0x5f30,1)
  end
 else
  key=nil
 end

end

--gfx import runtime begin.
--
--copy and paste this into your
--game cart.
--example usage after "end".
--

-- converts hex string
-- to actual number
function hex2num(str)
    return ("0x" .. str) + 0
end

--call this when you want to
--load your fullscreen
--graphics.
--this assumes a compressed
--format of <cnt>..<color>..
function load_stored_gfx(gfx)
    index = 0
    for i = 1, #gfx, 2 do
        cnt = hex2num(sub(gfx, i, i))
        local col = hex2num(sub(gfx, i + 1, i + 1))
        for j = 1, cnt do
            sset((index) % 128, flr((index) / 128), col)
            index += 1
        end
    end
end

--call this to go back to
--the original graphics stored
--on the cart.
--eg.after displaying title
--screen.
function restore_gfx()
    reload(0x0, 0x0, 0x2000)
end

--
--gfx import runtime end.
--
story_gfx =
"fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc9cf0f0f0306cf0f0f030fcbc10fefefe1e106c10fefefe1e10fcbc108e77fefe1e106c108efb8bfe10fcbc107e27161716171627fefe106c107e1bf7871bee10fcbc107e27161716171627fefe106c107e1bf7871bee10fcbc108e17161716171617fefe1e106c107e1b372017201720172027201730171bee10fcbc108e17161716171617fefe1e106c107e1b3710271027102710171017103710271bee10fcbc108e17161716171617fefe1e106c107e1b372017201710272027202710271bee10fcbc108e17161716171617fefe1e106c107e1b4710171027102710171017103710371bde10fcbc108e79fefe1e106c108e1b2720172017201710171017202710371bde10fcbc107e393f39fe1e707e106c108e1bf7871bde10fcbc106e395f39fe1f706e106c108e1b272027201720171017301720371bde10fcbc105e391f17102f101729fe3f605e106c108e1b27101710171027102710171017101710471bde10fcbc105e391f17102f101729ee10174f405e106c108e1b272027201710271017301720371bde10fcbc104e492f1c2f1c1f19fe10174f405e106c108e1b2710171017102710271017103710471bde10fcbc103e193e271c57194fae8f305e106c108e1b2710171017201720171017103720371bde10fcbc106e5712171c272e3f108e9f205e106c108e1bf7871bde10fcbc105eb7191e3f307e9f105e106c108e1bf7871bde10fcbc105e6712572e607e9f5e106c108e1bf7871bde10fcbc105e271e671e273e704eb04e106c108e1b2730172047202740371bde10fcbc105e271e671e274ef0703e106c108e1b5710271027103710771bde10fcbc105e271e671e275ef0702e106c108e1bf7871bde10fcbc105e271e671e276ef0701e106c108e1bf7871bde10fcbc105e171f1e671e277ef0601e106c108e1bf7871bde10fcbc105e2f1e671e2f9ef0401e106c108e1b572b372b271b272b171b271bde10fcbc106e1f1e602e1fbef0201e106c108e1b471b271b472b571b371bde10fcbc108e60eef0406c109e1bf7871bce10fcbc108e60eef0406c109e1bf7871bce10fcbc108e60eef0406c109e1b371017202710172037201710371bce10fcbc108e60eef0406c109e1b471057107710471bce10fcbc108e60eef0101e206c109e1bf7871bce10fcbcf0f0f0306cf0f0f030fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc8cf0f0f0306cf0f0f030fcbc10fe5e77fe4e106c10ce10f66610be10fcbc10fe4e27161716171627fe3e106c10be10f68610ae10fcbc10fe4e27161716171627fe3e106c10be1046f04610ae10fcbc10fe5e17161716171617fe4e106c10be103610f5103610ae10fcbc10fe5e17161716171617fe4e106c10be1026107514351b55102610ae10fcbc10fe5e17161716171617fe4e106c10be102610451b1514751b25102610ae10fcbc10fe5e17161716171617fe4e106c10be10261055141914651425102610ae10fcbc10fe5e79fe4e106c10be102610251415143914151425141925102610ae10fcbc10fe4e392f49fe3e106c10be102610351459141914151435102610ae10fcbc10fe3e394f49fe2e106c10be10363514191a191a14191a1924353610ae10fcbc10fe3e2917102f101739fe2e106c10be10463514191b391b1a1914254610ae10fcbc10fe2e3917102f101739fe2e106c10be20561514192a192a29145620ae10fcbc10fe2e396f39fe2e106c10be30f64630ae10fcbc10fe1e496f49fe1e106c10be70b670ae10fcbc10fe192e1987191e19fe1e106c10be1066b06610ae10fcbc10fe2e195712472e19fe106c10be2034e03430ae10fcbc10fe3ea719fe2e106c10be10161b29e61b19241610ae10fcbc10fe3e571247fe3e106c10bef0a0ae10fcbcf040374037f0406c10be10568456342610ae10fcbc10f434374437f434106c10be5014495430293420ae10fcbc10f4443714193719848224106c10be104614191b295436191b341610ae10fcbc10f4242d3f2d3f2df424106c10be50a4a0ae10fcbc10d4422d3f2d3f2df424106c10be10f68610ae10fcbc1024926419141b191b491b19a284106c10bef0a0ae10fcbc10f4341b291b391b29f434106c10be10f58510ae10fcbc10f454391b291bf444106c10be10f58510ae10fcbc10f434193449241bf424106c10be10f58510ae10fcbc10548244321b3219a49224106c10be10f58510ae10fcbc10f4741bf484106c10be10f58510ae10fcbc10f4f4f414106c10be10f58510ae10fcbcf0f0f0306cf0f0f030fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcacf0f0f030fcfcfcfcfc5c10f8f8f81810fcfcfcfcfc5c10f8f8f81810fcfcfcfcfc5c10f8f8f81810fcfcfcfcfc5c10f8f8f81810fcfcfcfcfc5c109877f8f810fcfcfcfcfc5c108827161716171627f8e810fcfcfcfcfc5c108827161716171627f8529810fcfcfcfcfc5c109817161716171617e82249a210fcfcfcfcfc5c109817161716171617d822699210fcfcfcfcfc5c109817161716171617d812799210fcfcfcfcfc5c109817161716171617c814191b591b198210fcfcfcfcfc5c109879c814192b392b198210fcfcfcfcfc5c108889c814192b292b29424410fcfcfcfcfc5c1078792fc814591b497410fcfcfcfcfc5c10787917101fb814a97410fcfcfcfcfc5c10787917102fa814791b297410fcfcfcfcfc5c1078793fb814191b191b292b297410fcfcfcfcfc5c1078793fb814192b193b397410fcfcfcfcfc5c10681918692fc812a97210fcfcfcfcfc5c106819186917e8f22210fcfcfcfcfc5c106819186927f8f810fcfcfcfcfc5c1088273947f8e810fcfcfcfcfc5c1078373947f8e810fcfcfcfcfc5c1078473947f8d810fcfcfcfcfc5c10686719271837f8c810fcfcfcfcfc5c106827186728371f6df84810fcfcfcfcfc5c106827186748171fcdd810fcfcfcfcfc5c10682f1860c86dd810fcfcfcfcfc5c108880f8f810fcfcfcfcfc5c1088302830f8f810fcfcfcfcfc5cf0f0f030fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc"

-->8
--draw
function draw_edit()
 -- background
 fillp(0b11001100001100111100110000110011)
 rectfill(0,0,127,127,33)
 fillp(▒)
 line(63,0,63,127,13)
 line(0,63,127,63,13)
 fillp()

 draw_menu()

 -- draw sprite
 if selspr then
  wrapmspr(selspr,63,63)
 end

 -- blinking dot
 if (time()*2)%1<0.5 then
  pset(63,63,rnd({8,13,7,15}))
 end
end

function draw_list()
 fillp(0b11001100001100111100110000110011)
 rectfill(0,0,127,127,33)
 fillp(▒)
 line(63,0,63,127,13)
 line(0,63,127,63,13)
 fillp()

 draw_menu()

 -- draw sprite
 local mymnu=menu[cury][curx]
 if mymnu then
  wrapmspr(mymnu.cmdy,63,63)
 end

 if (time()*2)%1<0.5 then
  pset(63,63,rnd({8,13,7,15}))
 end
end

function draw_table()
 cls(2)
 draw_menu()
end

function draw_menu()

 --spr(0,0,0,16,16)

	if menu then
		for i=1,#menu do
		 for j=1,#menu[i] do
		  local mymnu=menu[i][j]
		  local c=mymnu.c or 13
		  if i==cury and j==curx then
		   c=7
		   if _upd==upd_type then
		    c=0
		   end
		  end

		  bgprint(mymnu.w,mymnu.x+scrollx,mymnu.y+scrolly,13)
		  bgprint(mymnu.txt,mymnu.x+scrollx,mymnu.y+scrolly,c)
		 end
		end
 end

 if _upd==upd_type then
  local mymnu=menu[cury][curx]

  local txt_bef=sub(typetxt,1,typecur-1)
  local txt_cur=sub(typetxt,typecur,typecur)
  local txt_aft=sub(typetxt,typecur+1)
  txt_cur=txt_cur=="" and " " or txt_cur

  if (time()*2)%1<0.5 then
   txt_cur="\^i"..txt_cur.."\^-i"
  end

  local txt=txt_bef..txt_cur..txt_aft
		bgprint(txt,mymnu.x+scrollx,mymnu.y+scrolly,7)
 end

end


-->8
--update
function update_edit()
 refresh_edit()

 if btnp(⬆️) then
  cury-=1
 end
 if btnp(⬇️) then
  cury+=1
 end
 cury=(cury-1)%#menu+1
 cury-=mscroll
 cury=mid(1,cury,#menu)

 if cury==1 then
  curx=1
  if btnp(⬅️) then
   selspr-=1
  elseif btnp(➡️) then
   selspr+=1
  end
  selspr=mid(1,selspr,#data)
 elseif cury==10 then
  curx=1
 else
  curx=2
 end

 if btnp(🅾️) then
  _drw=draw_list
  _upd=update_list
  refresh_list()
  cury=selspr
  curx=1
  scrolly=0
  scrollx=0
  return
 end

 if btnp(❎) then
  local mymnu=menu[cury][curx]
  if mymnu.cmd=="editval" then
   _upd=upd_type
 	 local s=tostr(data[mymnu.cmdy][mymnu.cmdx])
   if s=="[nil]" or s==nil then
    s=""
   end
   typetxt=s
   typecur=#typetxt+1
   typecall=enter_edit
  elseif mymnu.cmd=="delspr" then
			deli(data,selspr)
			selspr-=1
			if selspr==0 then
			 selspr=1
			end
			_drw=draw_list
			_upd=update_list
			refresh_list()
			cury=selspr
			curx=1
			scrolly=0
			scrollx=0
			return
  end
 end
end

function update_list()
 refresh_list()
 if btnp(⬆️) then
  cury-=1
 end
 if btnp(⬇️) then
  cury+=1
 end
 cury=(cury-1)%#menu+1
 cury-=mscroll
 cury=mid(1,cury,#menu)

 curx=1

 local mymnu=menu[cury][curx]
 if mymnu.y+scrolly>110 then
  scrolly-=4
 end
 if mymnu.y+scrolly<10 then
  scrolly+=4
 end
 scrolly=min(0,scrolly)

 if mymnu.x+scrollx>110 then
  scrollx-=2
 end
 if mymnu.x+scrollx<20 then
  scrollx+=2
 end
 scrollx=min(0,scrollx)

 if btnp(❎) then
  local mymnu=menu[cury][curx]
  if mymnu.cmd=="newline" then
   add(data,{0,0,0,0,0,0})
  elseif mymnu.cmd=="editspr" then
   selspr=mymnu.cmdy
   _upd=update_edit
   _drw=draw_edit
   scrolly=0
   scrollx=0
   refresh_edit()
   cury=1
  end
 end
end

function update_table()
 refresh_table()

 if btnp(⬆️) then
  cury-=1
 end
 if btnp(⬇️) then
  cury+=1
 end
 cury=(cury-1)%#menu+1
 cury-=mscroll
 cury=mid(1,cury,#menu)

 if btnp(⬅️) then
  curx-=1
 end
 if btnp(➡️) then
  curx+=1
 end
 if cury<#menu then
  curx=(curx-2)%(#menu[cury]-1)+2
 else
  curx=1
 end
 local mymnu=menu[cury][curx]
 if mymnu.y+scrolly>110 then
  scrolly-=4
 end
 if mymnu.y+scrolly<10 then
  scrolly+=4
 end
 scrolly=min(0,scrolly)

 if mymnu.x+scrollx>110 then
  scrollx-=2
 end
 if mymnu.x+scrollx<20 then
  scrollx+=2
 end
 scrollx=min(0,scrollx)

 if btnp(❎) then
  local mymnu=menu[cury][curx]
  if mymnu.cmd=="edit" then
   _upd=upd_type
   typetxt=tostr(mymnu.txt)
   typecur=#typetxt+1
   typecall=enter_table
  elseif mymnu.cmd=="newline" then
   add(data,{0})
  elseif mymnu.cmd=="newcell" then
   add(data[mymnu.cmdy],0)
  end
 end
end

function upd_type()
 if key then
  if key=="\r" then
   -- enter
   poke(0x5f30,1)
   typecall()
   return
  elseif key=="\b" then
   --backspace
   if typecur>1 then
    if typecur>#typetxt then
	    typetxt=sub(typetxt,1,#typetxt-1)
	   else
			  local txt_bef=sub(typetxt,1,typecur-2)
			  local txt_aft=sub(typetxt,typecur)
			  typetxt=txt_bef..txt_aft
	   end
	   typecur-=1
   end
  else
   if typecur>#typetxt then
    typetxt..=key
   else
		  local txt_bef=sub(typetxt,1,typecur-1)
		  local txt_aft=sub(typetxt,typecur)
		  typetxt=txt_bef..key..txt_aft
   end
   typecur+=1
  end
 end

 if btnp(⬅️) then
  typecur-=1
 end
 if btnp(➡️) then
  typecur+=1
 end
 typecur=mid(1,typecur,#typetxt+1)
end
-->8
--tools

function bgprint(txt,x,y,c)
 print("\#0"..txt,x,y,c)
end

function split2d(s)
 local arr=split(s,"|",false)
 for k, v in pairs(arr) do
  arr[k] = split(v)
 end
 return arr
end

function wrapmspr(si,sx,sy)
 if si==nil then
  bgprint("[nil]",sx-5*2+1,sy-2,14)
  return
 end
 if myspr[si]==nil then
  bgprint("["..si.."]",sx-5*2+1,sy-2,14)
  return
 end

 local ms=myspr[si]

 if ms[8] then
  --check for loops
  if ms[8]==si then
   bgprint("[loop]",sx-6*2+1,sy-2,14)
   return
  else
   if checkloop(ms,10) then
    bgprint("[loop]",sx-6*2+1,sy-2,14)
    return
   end
  end
 end
 mspr(si,sx,sy)
end

function checkloop(ms,depth)
 depth-=1
 if depth<=0 then
  return true
 end

 if ms==nil then
  return true
 end

 if ms[8] then
  return checkloop(myspr[ms[8]],depth)
 else
  return false
 end
end

function mspr(si,sx,sy)
 local ms=myspr[si]
 sspr(ms[1],ms[2],ms[3],ms[4],sx-ms[5],sy-ms[6],ms[3],ms[4],ms[7]==1)
 if ms[7]==2 then
  sspr(ms[1],ms[2],ms[3],ms[4],sx-ms[5]+ms[3],sy-ms[6],ms[3],ms[4],true)
 end

 if ms[8] then
  mspr(ms[8],sx,sy)
 end
end

function spacejam(n)
 local ret=""
 for i=1,n do
  ret..=" "
 end
 return ret
end
-->8
--i/o
function export()
 local s=arrname.."=split2d\""

 for i=1,#data do
  if i>1 then
   s..="|"
  end
  for j=1,#data[i] do
	  if j>1 then
	   s..=","
	  end
	  s..=data[i][j]
  end
 end

 s..="\""
 printh(s,file,true)
 add(msg,{txt="exported!",t=120})
 --debug[1]="exported!"
end
-->8
--ui
function refresh_edit()
 menu={}

 add(menu,{{
	 txt="< sprite "..selspr.." >",
	 w="",
	 cmd="sprhead",
	 x=2,
	 y=2
 }})

 local lab={"  x:","  y:","wid:","hgt:"," ox:"," oy:"," fx:","nxt:"}

	for i=1,8 do
	 local s=tostr(data[selspr][i])

	 if s==nil then
	  s="[nil]"
	 end

		add(menu,{
			{
			 txt=lab[i],
			 w="    ",
			 x=2,
			 y=3+i*7
			},{
			 txt=s,
			 w=spacejam(#s),
			 cmd="editval",
			 cmdy=selspr,
			 cmdx=i,
			 x=2+16,
			 y=3+i*7
			}
		})
 end

 add(menu,{{
	 txt="delete",
	 w="",
	 cmd="delspr",
	 x=2,
	 y=4+9*7
 }})
end

function refresh_list()
 menu={}
 for i=1,#data do
  local lne={}
  local linemax=#data[i]
  if i==cury then
   linemax+=1
  end
  add(lne,{
	  txt="spr "..i,
	  w="",
	  cmd="editspr",
	  cmdy=i,
	  x=2,
	  y=-4+6*i
  })
  add(menu,lne)
 end
 add(menu,{{
  txt=" + ",
  w="   ",
  cmd="newline",
  x=2,
  y=-4+6*(#data+1)+2,
 }})
end

function refresh_table()
 menu={}
 for i=1,#data do
  local lne={}
  local linemax=#data[i]
  if i==cury then
   linemax+=1
  end
  add(lne,{
	  txt=i,
	  w="   ",
	  cmd="",
	  x=4,
	  y=-4+8*i,
	  c=2
  })
  for j=1,linemax do
   if j==#data[i]+1 then
			 add(lne,{
			  txt="+",
			  w=" ",
			  cmd="newcell",
			  cmdy=i,
			  x=-10+14*(j+1),
			  y=-4+8*i,
			 })
		 else
		  add(lne,{
		   txt=data[i][j],
		   cmd="edit",
		   cmdx=j,
		   cmdy=i,
		   x=-10+14*(j+1),
		   y=-4+8*i,
		   w="   "
		  })
   end
  end
  add(menu,lne)
 end
 add(menu,{{
  txt=" + ",
  w="   ",
  cmd="newline",
  x=4,
  y=-4+8*(#data+1),
 }})
end

function enter_table()

 local mymnu=menu[cury][curx]
 local typeval=tonum(typetxt)
 if typeval==nil then
  if mymnu.cmdx==#data[mymnu.cmdy] and typetxt=="" then
   --delete cell
   deli(data[mymnu.cmdy],mymnu.cmdx)
   if mymnu.cmdx==1 then
    deli(data,mymnu.cmdy)
   end
   _upd=update_table
   return
  end
  typeval=0
 end

 data[mymnu.cmdy][mymnu.cmdx]=typeval
 _upd=update_table
 refresh_table()
end

function enter_edit()

 local mymnu=menu[cury][curx]
 local typeval=tonum(typetxt)

 if mymnu.cmdx==8 then
  if typeval!=nil then
   if data[mymnu.cmdy][7]==nil then
    data[mymnu.cmdy][7]=0
   end
  end
 end

 if typeval==nil then
  if mymnu.cmdx>=7 and mymnu.cmdx==#data[mymnu.cmdy] then
   deli(data[mymnu.cmdy],mymnu.cmdx)
  else
   data[mymnu.cmdy][mymnu.cmdx]=0
  end
 else
  data[mymnu.cmdy][mymnu.cmdx]=typeval
 end

 _upd=update_edit
 refresh_edit()
end
__gfx__
bbbbbbbb1111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbb111bbbbbbbbbbbbbbbbbbb
bbbbbbb111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111b11111bbbbbbbbbbbbbbbbbb
bbbbbb1111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11122222222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111111111bbbbbbbbbbbbbbbbb
bbbbbb1111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbb1112211111111111221bbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111111bbbbbbbbbbbbbbbb
bbbbb11112222111122111bbbbbbbbbbbbbbbbbbbbbbbbbbbbb1122222222222222221bbbbbbbbbbbbbbbbbbbbbbbbb11111111111111111bbbbbbbbbbbbbbbb
bbbbb11128888222288211bbbbbbbbbbbbbbb1111bbbbbbbbbb1122222211111122221bbbbbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbb
bbbbb11128888888888211bbbbbbbbbbbbb112221bbbbbbbbbb1122222222222222221bbbbbbbb1111bbbbbbbbbbb111111111111111111111bbbbbbbbbbbbbb
bbbbb11128111888811121bbbbbbbbbbbb1222221bbbbbbbbbb1122221111222111121bbbbbbbb122211bbbbbbbbbbb11111111111111111111bbbbbbbbbbbbb
bbbbb112882711881172211bbbbbbbbbb12222221bbbbbbbbbb1122222711222271121bbbbbbbb1222221bbbbbbbbbb11111111111111111bbbbbbbbbbbbbbbb
bbbb1112888222882228211bbbbbbbbbb12222221bbbbbbbbb12212222222222212221bbbbbbbb12222221bbbbbbbbb11111721111721111bbbbbbbbbbbbbbbb
bbb18112888888888888211bbbbbbbbbb1222111bbbbbbbbbb12222222222222212221bbbbbbbb12222221bbbbbbbbb11111771111771111bbbbbbbbbbbbbbbb
bbb18112888888888188211bbbbbbbbb1222221bbbbbbbbbbb12222222222222212221bbbbbbbbb1112221bbbbbbbbb11111111111111111bbbbbbbbbbbbbbbb
bbb18111881288888188211bbbbbbbbb122221bbbbbbbbbbbbb1112222222221221221bbbbbbbbbb1222221bbbbbb1111122222222122221bbbbbbbbbbbbbbbb
bbbb1211181288811888111bbbbbbbbb1222221bbbbbbbbbbbb1122222222222112221bbbbbbbbbbb122221bbbbb122218888888881888221bbbbbbbbbbbbbbb
bbbbb121181281111118821bbbbbbbbb1222221bbbbbbbbbbbb1122222222222222221bbbbbbbbbb1222221bbbbb128188888881888188821bbbbbbbbbbbbbbb
bbbbb122281211111111821bbbbbbbbb1222221bbbbbbbbbbbb1112222111111111221bbbbbbbbbb1222221bbbbbb12888888881888188821bbbbbbbbbbbbbbb
bbbbbb12281211222221821bbbbbbbbb1222221bbbbbbbbbbbbb1112222177aa771221bbbbbbbbbb1222221bbbbbbb1288888882111288821bbbbbbbbbbbbbbb
bbbbbbb1281218111181881bbbbbbbbb12222221bbb111bbbbb1111122221111112221bbbbbbbbbb1222221bbbbbbbb128888888222888821bbbbbbbbbbbbbbb
bbbbbbb128811888888881bbbbbbbbbb122222221112221bb111111111222222222221bbbbbbbbb12222221bbbbbbbb112222228888888821bbbbbbbbbbbbbbb
bbbbbbb118888888218881bbbbbbbbbb1222222211122221111112211112222222221bbbbb1111122222221bbbb111111111111881181111111111bbbbbbbbbb
bbbbbbb121188888288881bbbbbbbbbb11222222112222221111a2222111111111111111111111122222221bbbb11111111111188888111111111bbbbbbbbbbb
bbbbbbb122218888888881bbbbbbbbbb112222221122222211122aa22211111111111111112222112222221bbbbb1111111111128818111111111bbbbbbbbbbb
bbbbbbb12222111111111bbbbbbbbbbb11222221122222211111111aaaa2222222aaa111122222212222211bbbbb11111111111111111111111111bbbbbbbbbb
bbbbbb11122222222221bbbbbbbbbbbbb11222222222222111111111122aaaaaaa111111122222222222211bbbb1111111111171eeee1111111111bbbbbbbbbb
bbbbb1ccc128888882211111bbbbbbbbb11122222222221111111111111122221111111112222222222221bbbbb1111111111171eee17111111111bbbbbbbbbb
bbb11c1ccc18888818221c1c1bbbbbbbbb1111222222211111111111111112211111111111222222222211bbbb111111111111771ee17111111111bbbbbbbbbb
bb11ccc1ccc188888821cc1c11bbbbbbbbb11111111111111111111111111111111111111112222222111bbbb1111111111111771ee17111111111bbbbbbbbbb
b1c1ccc11ccc1188881cc1cc1c1bbbbbbbbbbb1111111111111111111111111111111111111111111111bbbb11111111111111771ee17111111111bbbbbbbbbb
b1c1ccc1c1cccc1881cc1c1cc1c1bbbbbbbbbbbbbbbbbb11111111111111111111111111111111111bbbbbbb11111111111111771ee171111111111bbbbbbbbb
1cc1cc1ccc1ccc111cc11c1cc1cc1bbbbbbbbbbbbbbbbb111111111111111111111111111bbbbbbbbbbbbbb111111111111111771ee171111111111bbbbbbbbb
1c1ccc1cc1c111cc111cccc1c1111bbbbbbbbbbbbbbbbbb11111111111111111111111111bbbbbbbbbbbbbb111111111111111771ee171111111111bbbbbbbbb
1c1ccc1cc1cc1ccc1cc1cccc122221bbbbbbbbbbbbbbbbbb111111111111111111111111bbbbbbbbbbbbbbb1111111111111117771e171111111111bbbbbbbbb
1c1c1121c1cc1ccc1cc1cccc118821bbbbbbbbbbbbbbbbbb111111111111111111111111bbbbbbbbbbbbbbb1111111111111117771e171111111111bbbbbbbbb
1c112221c1ccc1cc111111118888221bbbbbbbbbbbbbbbbbb11111111111111111111111bbbbbbbbbbbbbbb1111111111111117771e171111111111bbbbbbbbb
1122888211cc1111188888888888821bbbbbbbbbbbbbbbbbbb111111111111111111111bbbbbbbbbbbbbbbb1111111111111111771e1771111111111bbbbbbbb
12888888211188888888888888888221bbbbbbbbbbbbbbbbbb111111111111111111111bbbbbbbbbbbbbbbb1111111111111111771e1771111111111bbbbbbbb
12888888821222211188888888888821bbbbbbbbbbbbbbbbbbb11111111111111111111bbbbbbbbbbbbbbbb1111111111111111771e1771111111111bbbbbbbb
12888888888111122111188888888821bbbbbbbbbbbbbbbbbbb11111111111111111111bbbbbbbbbbbbbbbbb111111111111111771e1771111111111bbbbbbbb
b18888888888822211ccc1111111111bbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbb111111111111111771e1771111112111bbbbbbbb
bb18888888888211c1ccc1ccc1bbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbb11111111221111177111771111111211bbbbbbbb
bb1888888888811cc1ccc1ccc1bbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbbb1111112221111177771771111111211bbbbbbbb
bb11888888881c1cc1ccc1ccc1bbbbbbbbbbbbbbbbbbbbbb11bb111bb11bb11bbbbbbbbbbbbbbbbbbbbbbbbbb1111122211111177777771111111111bbbbbbbb
bb1c11888881cc1cc1cccc1cc1bbbbbbbbbbbbbbbbbbbbb12211222112211221bbbbbbbbbbbbbbbbbbbbbbbbb1111122111111177777771111111111bbbbbbbb
bb1c1c188111ccc1cc1ccc1cc1bbbbbbbbbbbbbbbbbbbb122222222222222221bbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117771777111111111bbbbbbbb
bb1c1cc11cc1ccc1cc1ccc1cc1bbbbbbbbbbbbbbbbbbbb122222222222222221bbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117777777111111111bbbbbbbb
bb1cc1cc1ccc1cc1cc1ccc1cc1bbbbbbbbbbbbbbbbbbbb12222221111111221bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117777777111111111bbbbbbbb
bb1cc1cc1ccc1cc1cc1ccc1c1bbbbbbbbbbbbbbbbbbbbb12222112222222121bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117771777111111111bbbbbbbb
bb11111111111111111111111bbbbbbbbbbbbbbbbbbbbb12221228888888211bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117777777111111111bbbbbbbb
bbbbbbbbb111111111111111111bbbbbbbbbbbbbbbbbbb12212888888888821bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111111111111111111111bbbbbbbb
bbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbbb12212888888888821bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bbbbbbbbbbbbbbbbbb
bbbbbbbbb11222221111111122111bbbbbbbbbbbbbbbbb12128211188881111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb117777771111bbbbbbbbbbbbbb
bbbbbbbb1118888822111112882111bbbbbbbbbbbbbbb112128227118817111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb117777777777771bbbbbbbbbbbbb
bbbbbbbb1118888188221121882111bbbbbbbbbbbbbb1881288822228812221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777777777771bbbbbbbbbbbb
bbbbbbbb1118888811888888118211bbbbbbbbbbbbbb1888888821118811121bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777777777777777771bbbbbbbbbbb
bbbbbbbb1118888888888888888211bbbbbbbbbbbbbb1888888882228812281bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777777111777771bbbbbbbbbbb
bbbbbbbb1128888811188881118821bbbbbbbbbbbbbbb181888888888881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177777777711222177771bbbbbbbbbbb
bbbbbbbb1288888877188887718821bbbbbbbbbbbbbbbb12888888888881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777777771122222211771bbbbbbbbbbb
bbbbbbbb1288888822288812228821bbbbbbbbbbbbbbbbb1288888888812881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777712288888821771bbbbbbbbbbb
bbbbbbb11188888888888818888821bbbbbbbbbbbbbbbbbb128888888228881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777128882222222171bbbbbbbbbbb
bbbbbb122218888888888818888821bbbbbbbbbbbbbbbbbb112888881118881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777777712888888888821bbbbbbbbbbbb
bbbbbb128888888888888881888821bbbbbbbbbbbbbbbbbb121288818888881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177777771111188811111bbbbbbbbbbbbb
bbbbbbb1228888888888188188821bbbbbbbbbbbbbbbbbbb12212288881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777117777711177771bbbbbbbbbbbbb
bbbbbbbb118882188888211288821bbbbbbbbbbbbbbbbbbb1222111111211bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17111217777718177771bbbbbbbbbbbbb
bbbbbbbb128888218888822888821bbbbbbbbbbbbbbbbbbb1228822222821bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1222817771718177171bbbbbbbbbbbbb
bbbbbbbb128888218888888888821bbbbbbbbbbbbbbbbbbb1288888881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1288817777718177771bbbbbbbbbbbbb
bbbbbbbb128888821888888111821bbbbbbbbbbbbbbbbbb11288888888881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1288881111188811111bbbbbbbbbbbbb
bbbbbbbbb1288882188888114411111bbbbbbbbbbbbbbb11111888888881111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17118888882288881281bbbbbbbbbbbbb
bbbbbbbbbb128888218888111144441bbbbbbbbbbbbbb1112221188888122221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177188888228888118821bbbbbbbbbbbbb
bbbbbbbbbb112288218888222211111bbbbbbbbbbbbb111222222111812222221bbbbbbbbbbbbbbbbbbbbbbbbbbbbb177718888888888888881bbbbbbbbbbbbb
bbbbbbbbb1771128888888888221bbbbbbbbbbbbbbb11122222222221222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbb177771888888888118881bbbbbbbbbbbbb
bbbbbb117777771222228888882111bbbbbbbbbbbb1112222222222222222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbb1777111888818888881bbbbbbbbbbbbbb
bbbb1171117777711111222222177711bbbbbbbbbb1122222222222212222222221bbbbbbbbbbbbbbbbbbbbbbbbbbb11111222111118888881bbbbbbbbbbbbbb
bbb177777111777777711111117771771bbbbbbbb112222222222221812222222221bbbbbbbbbbbbbbbbbbbbbbbbb144444444212221888811bbbbbbbbbbbbbb
bb17777777771177777111117777177771bbbbbbb112222222222221812222222221bbbbbbbbbbbbbbbbbbbbbbbb1444444444421222111111bbbbbbbbbbbbbb
b1777777777771117711111117111777771bbbbbb1122222122222188812221222221bbbbbbbbbbbbbbbbbbbbbb144444444444217771221221bbbbbbbbbbbbb
177777777777711711771117717117777771bbbbb1222222122222111112222122221bbbbbbbbbbbbbbbbbbbbb14444444444442177712221221bbbbbbbbbbbb
1777777777777117777711177171177777771bbbb1222221222221444441222212221bbbbbbbbbbbbbbbbbbbb1444444444444421777122212441bbbbbbbbbbb
1777777717777117777771117771177777771bbb12222221222221144414122212221bbbbbbbbbbbbbbbbbbb1444444444441142177771222124411bbbbbbbbb
17777777177771117777711177711777777771bb122222211222214144441222122221bbbbbbbbbbbbbbbbbb14444124444444111777712221244441bbbbbb11
177777777177771177777111717117777777771b122221188111141111111222122221bbbbbbbbbbbbbbbbb1444442124444444411777712212444441bbbb141
177777777717771177777111777117717777771b122218888888818888812222122221bbbbbbbbbbbbbbbbb14444421244444444441777122124444441bb141b
b17777777771171177777111117117771777771b121188888888888888812222111111bbbbbbbbbbbbbbbbb14444442124444444444177122212444421b141bb
b17777777777711177777111881881771777771bb1888888888888188881222218881bbbbbbbbbbbbbbbbbb14444444212244444444411122221222421141bbb
bb17777777777771177771888818881177777771bb188888811111111111222218881bbbbbbbbbbbbbbbbbb1444444442112444444444441222211122181bbbb
bbb1777777777771a11118811181188817777771bbb11111122221414414122218881bbbbbbbbbbbbbbbbbb14444444422212224444444441111bbb118821bbb
bbb1777777777771aa122888a81a818821777771bbbbbb12222221444144122218881bbbbbbbbbbbbbbbbb1444444444422211122244444441881b1414221bbb
bbbb177777777771aa128881111188882177771bbbbbbb11111111111111111111111bbbbbbbbbbbbbbbbb144444444444222221112244444188211441111bbb
bbbb117777777771aa128888a1881888217771bbbbbbbbbbbbbbbbb1111111111bbbbbbbbbbbbbbbbbbbbb144444444444422222211122211182214121bbbbbb
bbb1771117777771aa1281111111888221711bbbbbbbbbbbbbbbbb111111111111bbbbbbbbbbbbbbbbbbbb144444444444442222217711112211114211bbbbbb
bbb1777771111771a1111111777111111111bbbbbbbbbbbbbbbbb11111111111111bbbbbbbbbbbbbbbbbbb144444444444444222221777712221bb1121bbbbbb
bbb1777777777111177771117771177771bbbbbbbbbbbbbbbbbbb11111111111111bbbbbbbbbbbbbbbbbbb144444444444444422221777771221bbbb141bbbbb
bbb1777777777711777771117171177771bbbbbbbbbbbbbbbbbbb11112222222221bbbbbbbbbbbbbbbbbbbb1444444444444444222177777121bbbbb111bbbbb
bbb1777777777711777777117771177771bbbbbbbbbbbbbbbbbbb11122222222221bbbbbbbbbbbbbbbbbbbb1111111111111111111111111111bbbbb141bbbbb
bbb1777777777711777777117771177771bbbbbbbbbbbbbbbbbbb11111111121111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb177777777711777777777771177771bbbbbbbbbbbbbbbbbbb11222171111711bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb177777777711717777777171177771bbbbbbbbbbbbbbbbbb112222111121111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb1777777771171777777777117771bbbbbbbbbbbbbbbbbbb122222222221221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbb17777777117177777777711771bbbbbbbbbbbbbbbbbbbb122122222222121bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb177777711771777777771171bbbbbbbbbbbbbbbbbbbbbb11122222222121bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbb1111111111b11777717111bbbbbbbbbbbbbbbbbbbbbbb11222222211221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbb11111111bbbbbbbbbbbbbbbbbbbbbbbb11222222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1222222211221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb122222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11122222222211bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777122221221771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1171777111111177171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb11bbb1881bb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177771177111117717771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1881b18881b1881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177777717711177177771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb188811888818821bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777711111117777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb188811888218821b11bbbbbbbbbbbbbbbbbbbbbbbbbbb17777777777717777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8bbbbbbbbbbbbbbbbbb
bbbb1888818882188211821bbbbbbbbbb111b111bbbbbbbbb177711111777171777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bbbbbbbbbbbbbbbbbbb
bbbb1882818888188811821bbbbb111b1882122211bbbbbb177771aaa1777177777777771bbbbbbbbbbbbb777bbbbbbbbbbbbbbbbbb4bbbbbbbbbbbbbbbbbbbb
bbbbb188218882188218821bbbb1882128821aaa121bbbbb1777711111777171777771771bbbbbbbbbbb77777fbbbbbbbbbbbbbbb88488bbbbbbbbbbbbbbbbbb
bbbbb1882188821aaa18821bbbb18821288219991221bbbb1777777777777177777771771bbbbbbbbbb7777777fbbbbbbbbbbbb888848888bbbbbbbbbbbbbbbb
bb111b1882188219991821bbbb188218122181228821bbbb1777717777777177777771771bbbbbbbbb77ff7777ffbbbbbbbbbb88888288888bbbbbbbbbbbbbbb
b188211882188212218821bb11888888888888888821bbbb1777717777777177777717771bbbbbbbbbf777f77f44bbbbbbbbb8888822288882bbbbbbbbbbbbbb
b18882188888888888821bb122188888888888888821bbbb1777717777777177777717771bbbbbbbbbbf77fff499bbbbbbbbb8888888888882bbbbbbbbbbbbbb
bb1888218821821821821bb182188888218218818821bbbb1777771777777177777717771bbbbbbbbbb4ff444999bbbbbbbb888888888888882bbbbbbbbbbbbb
bb1888818821821821821bb182188888818818818821bbbb1777777177777717777177711bbbbbbbbbb4f4994949666bbbbb888888888888882bbbbbbbbbbbbb
bb188888882182182181bbb18888888882182182121bbbbb117777771711111111717771bbbbbbbbbbb94f494999bb6bbbbb888888888888822bbbbbbbbbbbbb
bbb18888882182182121bbb18888888882182182121bbbbbbb177777717777777717771bbbbbbbbbbbb99f494949bb6bbbbb888888888888822bbbbbbbbbbbbb
bbb18888888888888821bbbb1888888888888888821bbbbbbbb1777771777777777171bbbbbbbbbbbbb994999949bb6bbbbb888888888888222bbbbbbbbbbbbb
bbbb1888888888888821bbbbb188888888888888821bbbbbbbbb117771777777777111bbbbbbbbbbbbb994994949bb6bbbbbb8888888888222bbbbbbbbbbbbbb
bbbb1888888888888221bbbbbb18888888888888221bbbbbbbbb171111111111111171bbbbbbbbbbbbb994994999bb6bbbbbb8888888882222bbbbbbbbbbbbbb
bbbbb18888888888221bbbbbbbb188888888888221bbbbbbbbbb177777777717777771bbbbbbbbbbbbb999999994bb6bbbbbbb22288822222bbbbbbbbbbbbbbb
bbbbbb1888888882221bbbbbbbbb18888888882221bbbbbbbbbb111111111111111111bbbbbbbbbbbbb499999946666bbbbbbbb222222222bbbbbbbbbbbbbbbb
bbbbbbb122222222221bbbbbbbbbb1222222222221bbbbbbbbbb111111111111111111bbbbbbbbbbbbb644444446bbbbbbbbbbbbb22222bbbbbbbbbbbbbbbbbb
bbbbbbbb1111111111bbbbbbbbbbbb11111111111bbbbbbbbbbb111111111111111111bbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__map__
0000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
