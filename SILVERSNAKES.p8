pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
--main

--team silversnakes
--lance stutzman
--ernesto valenciana
--derek oda
--jared van natta

--flags
wall=0
text=1
interact=2
special=3
stairs=4
water=5

--consts
--completed by team
dirs={
	x={0,1,0,-1,1,1,-1,-1},
	y={1,0,-1,0,1,-1,1,-1}
}

function _init()
	initGame()
end

-->8
--drawing

function clearScreen()
	cls()
end
--completed by team
function drawPlayer()
	local plr_spr=waterTile(plr.x,plr.y) and 18 or 1
	spr(plr_spr,plr.x*8,plr.y*8)
end
--lance
function monsterData(mon)
	drawMonster(mon)
	drawHPbar(mon)
end
--lance & jared
function drawAllMonsters()
	foreach(monsters,monsterData)
end
--derek
function drawFramedRect(x,y,w,h)
	rectfill(x,y,x+w,y+h,0)
	rectfill(x+1,y+1,x+w-1,y+h-1,6)
	rectfill(x+2,y+2,x+w-2,y+h-2,0)
end
--jared 
function drawFog()
	local dun_index=isDungeon()
	if not dun_index then return end
	local curr_fog=fog[dun_index]
	for x=1,16 do
		for y=1,16 do
			if curr_fog[x][y] then
				spr(127,(map_x+x-1)*8,(map_y+y-1)*8)
			end
		end
	end
end
--jared
function unfog()
	local dun_index=isDungeon()
	if not dun_index then return
	end
	local curr_fog=fog[dun_index]
	for x=1,16 do
		for y=1,16 do
			local fx,fy=map_x+x-1,map_y+y-1
			if dist(plr.x,plr.y,fx,fy)<4 then
				curr_fog[x][y]=false
			end
		end
	end
end
--derek
function framedText(text,x,y,col)
	for i=1,8 do
			print(text,x+dirs.x[i],y+dirs.y[i],0)		
	end
	print(text,x,y,col)
end
--derek
function shadowText(text,x,y,text_col,shadow_col)
	print(text,x,y+1,shadow_col)
	print(text,x,y,text_col)
end
--derek
function drawMessage()
	if message_timer>0 and 
				active_message~="" then
		local x=64-#active_message*2+map_x*8
		local y=64-flr(20/-message_timer)+map_y*8
		framedText(active_message,x,y,6)
		message_timer-=1
	end
end
-->8
--map and camera
--team
function drawMap()
	map(0,0,0,0,128,64)
end

function setCamera()
	map_x=flr(plr.x/(16))*16
	map_y=flr(plr.y/(16))*16
	camera(map_x*8,map_y*8)
end

--handling functions
--team
function walkable(x,y,switches)

	if not switches then switches={} end

	local tile=mget(x,y)

	if waterTile(x,y) and switches.is_floater then
		return true
	elseif not isSpecial(x,y) or not switches.is_player then
		return not fget(tile,wall)
	else
		--lamp, boat cloak walking
		--completed by jared and team
 	if tile==97 and inventory.lamp then
 		return true
		elseif tile==96 and inventory.boat then
			return true
		elseif tile==112 and inventory.cloak then
			return true
		else
			return false
		end
 end
end
--is text
--derek
function isText(x,y)
	local tile=mget(x,y)
	return fget(tile,text)
end
--is interactive
--jared
function isInteractive(x,y)
	local tile=mget(x,y)
	return fget(tile,interact)
end
--is special item/tile
--ernesto
function isSpecial(x,y)
	local tile=mget(x,y)
	return fget(tile,special)
end
--is stairs
--jared
function isStairs(x,y)
	local tile=mget(x,y)
	return fget(tile,stairs)
end
--is water
--jared
function waterTile(x,y)
	local tile=mget(x,y)
	return fget(tile,water)
end
--returns map index
--jared
function mapAreaIndex()
	return (map_y/16)*8+map_x/16
end
--returns location
--jared
function locationIndex(x,y)
	return y*128+x
end
--returns x y coordinates
--jared
function coordinateIndex(index)
	return index%128,flr(index/128)
end
--border tiles
--jared
function randomBorderTile()
	local tries,x,y=0
	local dirs={"left","right","up","down"}
	repeat
		local offset=flr(rnd(16))
		local where=rnd(dirs)
		if where=="left" then
			x=map_x
			y=map_y+offset
		elseif where=="right" then
			x=map_x+15
			y=map_y+offset
		elseif where=="up" then
			x=map_x+offset
			y=map_y
		elseif where=="down" then
			x=map_x+offset
			y=map_y+15
		end
		tries+=1
		if tries>=10000 then
			return nil,nil
		end
	until walkable(x,y)

	return x,y
end

--marks out of screen
--jared
function outofScreen(tx,ty)
	return tx<map_x or 
								tx>map_x+15 or
								ty<map_y or
								ty>map_y+15
end
--is safe to walk
--jared
function safeTile()
	return not map_areas[mapAreaIndex()+1]
end
-->8
--player

--make player
--team
function makePlayer()
	plr={
	 x=54,
	 y=23,
		lvl=1,
		xp=0,
		hp=20,
		hpmax=20,
		atk=3,
		def=0,
		gold=0,
		attack=attack,
		die=function()
			transitionOut()
			t_cover=0
			
			music(16)
			game_over_pos=280
			map_x=0
			map_y=0
			_draw=drawGameOver
			_update=updateGameOver 
		end
	}
end
--check level up
--jared
function checkLevelUp()
	local to_level=nextLevel(plr.lvl)
	if plr.xp>=to_level then
		plr.lvl+=1
		plr.hpmax+=10
		plr.xp-=to_level
		plr.hp=plr.hpmax
		sfx(51)
		message("level up!",2)
	end
end
--create xp req for next level
--team
function nextLevel(lvl)
	return (lvl+1)*(lvl+1)*4
end
-->8
--gameplay

--update game function
--team
function updateGame()
	if t_cover>0 then
		return
	end
	
	attacked=false
	moved=false
	local move_x,move_y=handleKeys()
	if btnp(❎) and not active_text then
		if stats_mode==drawStatusBar then	
			stats_mode=drawStats	
			sfx(59)
 	else
			stats_mode=drawStatusBar
			sfx(58)
		end
	end
	
	if active_text or 
				stats_mode==drawStats then
		return
	end
	

	
	if move_x==0 and move_y==0 then
		return
	end
	--handles variations of game state
	--if something is stairs
	--if it is interactive
	--if it is in a dungeon 
	--if it is a dungeon and walkable
	--if it is walkable, move player
	--if you're up against a wall

	local tx,ty=plr.x+move_x,plr.y+move_y
	local mon=monsterLocation(tx,ty)
	if isText(tx,ty) then
		displayText(tx,ty)
	elseif mon then
		handleAttack(mon)
	elseif isInteractive(tx,ty) then
		handleInteract(tx,ty)
	elseif isDungeon() and outofScreen(tx,ty) then
		wallHit()
	elseif isStairs(tx,ty) then
		handleStairs(tx,ty)
	elseif walkable(tx,ty,{is_player=true}) then
		movePlayer(tx,ty)
	else
		wallHit()
	end
	--if player moves then mosnters move
	if moved then
		moveMonsters()
		handleSpawning()
		if finalDungeon() then
			finalDungeonUpdate()
		end
		--easter egg
		itemTurn()
		ringRegen()
	end
end
--x y monster location
--lance
function monsterLocation(x,y)
	for m in all(monsters) do
		if m.x==x and m.y==y then
			return m
		end
	end
	return nil
end
--movement 
--jared
function handleKeys()
	local move_x,move_y=0,0
	if btnp(⬅️) then 
		move_x=-1 
	elseif btnp(➡️) then
	 move_x=1
	elseif btnp(⬇️) then
	 move_y=1
	elseif btnp(⬆️) then
	 move_y=-1
	end

	return move_x,move_y
end
--attack 
--lance and jared
function attack(self,other)
	other.hp-=max(0,self.atk-other.def)+flr(rnd(2))
	if other.hp<=0 then
		other:die()
		if self==plr then
			plr.xp+=other.xp
			plr.gold+=other.gold+ceil(rnd(other.gold))
			checkLevelUp()
		end
		--boss function
		if other==dark_lord then
			transitionOut()
			map_x=0
			map_y=0
			good_ending=true
			music(16)
			_draw=drawEnding
			_update=updateEnding
		end
		--guarding the bridge
		if other==behemoth then
			addArmor(4)
			active_text={
				"the fire giant falls",
				"and you find the", 
				"fingerprint shield"
			}
		end
	end
end
--ernesto
function interactWith(obj)
	if not obj then return end
	if not obj.touched then
		sfx(59)
		if not obj.repeatable then
			obj.touched=true			
		end
		active_text=obj.text_before
		obj:action()
		
		if obj.touched then
			mset(obj.x,obj.y,obj.sprite_after)
		end
	
	else
		active_text=obj.text_after
	end
end
--easter egg
function heal()
	local healing_amount=plr.hpmax-plr.hp
	while healing_amount>0 and plr.gold>0 do
		
		plr.hp+=1
		healing_amount-=1
	end
	plr.gold=max(plr.gold,0)
	sfx(56)
end
--ernesto
function addWeapon(weapon)
	sfx(56)
	plr.atk=max(plr.atk,weapon)
end
--ernesto
function addArmor(armor)
	sfx(56)
	plr.def=max(plr.def,armor)
end

--derek
function displayText(x,y)
	active_text=getText(x,y)
	sfx(59)
end
--lance
function handleAttack(mon)
	sfx(61)
	plr:attack(mon)
	attacked=true
	moved=true
end
--ernesto
function handleInteract(x,y)
	local obj_index=locationIndex(x,y)
	local obj=story_map[obj_index]
	interactWith(obj)
end
--jared
function wallHit()
	sfx(62)
end
--jared
function handleStairs(x,y)
	local obj_index=locationIndex(x,y)
	local stair=stair_map[obj_index]
	local mx,my=coordinateIndex(stair)
	plr.x,plr.y=mx,my
	sfx(57)
	transitionOut()
	setCamera()
	
end
--team
function handleSpawning()
	if rnd()<map_danger[mapAreaIndex()+1] then
		spawnRandomMonster()
	end
end
--jared
function movePlayer(x,y)
	plr.x,plr.y=x,y
	sfx(63)
	moved=true
end
--easter egg
function itemTurn()
	if inventory.ring then
		ring_turn+=1
	end
	
	
end
--easter egg
function ringRegen()
	if inventory.ring and 
				ring_turn>15 and 
				plr.hp<plr.hpmax then
		plr.hp+=2
		sfx(54)
		ring_turn=0
	end
end




-->8
--text

--all of text section was done by jared and derek
function setupText()
	texts={}
	addText(54,19,
		{"the world was made whole",
		"by the power of the",
		"greater will",
		"and the elden ring",
		"was given to us",
		"now it has been destroyed",
		"and evil walks",
		"across the land" 
		})
	addText(49,20,
		{"a great sorcerer destroyed",
		"the elden ring"
		})
	addText(59,20,
		{"i heard you can find",
		"the shards of the elden ring",
		"in hard to reach places"
		})
	addText(53,27,
		{"now that evil walks the earth",
			"it isn't safe to travel"
		})	
	addText(50,23,
		{"talk to everyone you meet!",
		"everyone has a secret"
		})
	addText(49,29,
		{"the sage in the village to",
			"the east is very wise."
		})
	addText(58,27,
		{"there is a healer in the",
		 "eastern village"
		})
	addText(98,38,
		{"there is an iron sword",
		"in the north, it is a foul",
		"and cursed weapon"
		})
	addText(99,34,{
		"three shards of the elden ring",
		"were hidden in three dungeons",
		"in your quest you will need",
		"a lamp to guide you through",
		"the northern plagueland;",
		"a boat to navigate",
		"the waters of the south;",
  		"and a cloak to protect",
		"you from the snows",
		"of the north."
	})
	addText(99,40,{
		"an old magi lives alone",
		"to the southeast of here."
	})
	addText(105,45,{
		"there is another village",
		"to the northwest of the",
		"castle,just south of the",
		"icy mountains."
	})
	addText(110,41,{
		"beware the bridge to the",
		"south.a mighty behemoth",
		"guards the path",
		"to the lair of the",
		"glintstone sorcerer"
	})
	addText(103,34,{
		"if you travel around,you",
		"might find some old treasures",
		"buried or locked in chests."
	})
	addText(110,35,{
		"there is a stone circle",
		"to the north of here"
	})
	addText(107,33,{
		"there is a shipwright in the",
		"western village."
	})
	addText(20,26,{
		"if you want to dig something",
		"up, you need a shovel."
	})

	addText(25,22,{
		"western village"
	})
	addText(53,23,{
		"kill monsters for gold",
		"explore the world",
		"and learn its secrets"
	})
	addText(104,38,{
		"eastern village"
	})
end 
--derek
function addText(x,y,message)
	texts[x+y*128]=message
end

function getText(x,y)
	return texts[x+y*128]
end

function drawText()
	if active_text then
		text_x=map_x*8+4
		text_y=map_y*8+48-flr(#active_text/2)*6
		
		rectfill(text_x-2,text_y-2,text_x+121,text_y+#active_text*6+14,0)
		rectfill(text_x-1,text_y-1,text_x+120,text_y+#active_text*6+13,6)
		rectfill(text_x,text_y,text_x+119,text_y+#active_text*6+12,0)

		for i=1,#active_text do
			print(active_text[i],text_x+4,text_y+4+((i-1)*6),9)			
		end

		print("❎",text_x+110,text_y+#active_text*6+sin(time()*2)+6,6)
	end
	--gets player out of text boss
	if btnp(❎) and active_text then
		active_text=nil
		sfx(58)
	end
end

--derek
function message(text,duration)
	active_message=text
	message_timer=duration*30
end

-->8
--monsters
--lance
function makeMonster(x,y,kind)
	local monster={
		x=x,
		y=y,
		hp=kind.hp,
		hpmax=kind.hp,
		atk=kind.atk,
		def=kind.def,
		spd=kind.spd,
		xp=kind.xp,
		floater=kind.floater,
		gold=kind.gold,
		move_counter=0,
		sprite=kind.sprite,
		move=moveMonster,
		check_dir=findDirection,
		die=removeMonster,
		attack=attack,
		pal_swap=false
	}

	return monster
end
--lance
function makeToughMonster(x,y,kind)
	local monster={
		x=x,
		y=y,
		hp=kind.hp*2,
		hpmax=kind.hp*2,
		atk=kind.atk+2,
		def=kind.def+2,
		spd=max(1,kind.spd-1),
		xp=kind.xp*2,
		floater=kind.floater,
		gold=kind.gold*2,
		move_counter=0,
		sprite=kind.sprite,
		move=moveMonster,
		check_dir=findDirection,
		die=removeMonster,
		attack=attack,
		pal_swap=true
	}

	return monster
end
--lance and jared
function moveMonster(mon,mov_x,mov_y)
	if isDungeon() and dist(plr.x,plr.y,mon.x,mon.y)>4 then
		return
	end
	if not isDungeon() and mon.x<16 then
		return
	end
	mon.move_counter+=1

	local tx,ty=mon.x+mov_x,mon.y+mov_y
	if plr.x==tx and plr.y==ty then
		mon:attack(plr)
		if not attacked then
			sfx(60)			
		end

	elseif walkable(tx,ty,{is_floater=mon.floater}) and	mon.move_counter%mon.spd==0 and not monsterLocation(tx,ty) then
		mon.x+=mov_x
		mon.y+=mov_y
	end
end
--lance and jared, moves monster in direction of player
function findDirection(monster)
	local mx,my,px,py=monster.x,monster.y,plr.x,plr.y
	local mov_x,mov_y,tdist=0,0,999

	for i=1,4 do
		local tx,ty=mx+dirs.x[i],my+dirs.y[i]
		local new_dist=dist(tx,ty,px,py)
		if new_dist<=tdist and 
					walkable(tx,ty,{is_floater=monster.floater}) and 
					not monsterLocation(tx,ty) then
			tdist=new_dist
			mov_x,mov_y=dirs.x[i],dirs.y[i]
		end
		if isPlayerAt(tx,ty) then
			return dirs.x[i],dirs.y[i]
		end
	end	

	return mov_x,mov_y
end
--lance and jared
function isPlayerAt(x,y)
	return x==plr.x and y==plr.y
end
--lance
function drawMonster(monster)
	if monster.pal_swap then
		
	end
	
	spr(monster.sprite,
		monster.x*8,monster.y*8)
	
end
--on monster die, undraw
--lance
function removeMonster(self)
	del(monsters,self)
end
--lance
function moveMonsters()
	for m in all(monsters) do
		if not safeTile() or not outofScreen(m.x,m.y) then 
			m:move(m:check_dir())
		end
	end
end
--lance
function getRandomEnemy()
	local pool,mon,mon_data=map_areas[mapAreaIndex()+1]

	if not pool then
		return nil
	end
	mon=rnd(pool)

	mon_data=monster_types[mon]

	return mon_data
end

function spawnRandomMonster()
	local mon=getRandomEnemy()
	local x,y=randomBorderTile()
	if mon and x then
		add(monsters,makeMonster(x,y,mon))
	end
end
-->8
--data
--all monster types done by team
monster_types={
	skultula={
		hp=8,
		atk=0,
		def=0,
		spd=2,
		xp=1,
		gold=1,
		sprite=48
	},
	bandit={
		hp=10,
		atk=1,
		def=0,
		spd=2,
		xp=2,
		gold=2,
		sprite=49
	},
	zombie={
		hp=10,
		atk=1,
		def=2,
		spd=3,
		xp=3,
		gold=3,
		sprite=50
	},
	octork={
		hp=10,
		atk=2,
		def=1,
		spd=1,
		xp=4,
		gold=3,
		sprite=51,
		floater=true
	},
	spider={
		hp=10,
		atk=1,
		def=1,
		spd=1,
		xp=5,
		gold=2,
		sprite=52
	},
	scorpion={
		hp=10,
		atk=2,
		def=1,
		spd=2,
		xp=6,
		gold=3,
		sprite=53
	},
	swarm={
		hp=12,
		atk=2,
		def=2,
		spd=2,
		xp=7,
		gold=2,
		sprite=54,
		floater=true
	},
	demon={
		hp=15,
		atk=3,
		def=3,
		spd=1,
		xp=10,
		gold=4,
		sprite=55
	},
	dragon={
		hp=18,
		atk=3,
		def=3,
		spd=1,
		xp=15,
		gold=4,
		sprite=59
	},
	giant={
		hp=20,
		atk=3,
		def=4,
		spd=3,
		xp=20,
		gold=5,
		sprite=60
	},
	ooze={
		hp=10,
		atk=2,
		def=3,
		spd=3,
		xp=10,
		gold=10,
		sprite=61
	},
	bat={
		hp=8,
		atk=2,
		def=1,
		xp=10,
		spd=1,
		gold=3,
		floater=true,
		sprite=62
	},
	behemoth={
		hp=30,
		atk=2,
		def=1,
		spd=0,
		xp=15,
		gold=15,
		sprite=56
	},
	darklord={
		hp=50,
		atk=3,
		def=2,
		spd=1,
		xp=20,
		gold=0,
		sprite=58
	}
}
--ernesto
weapons={
	nil,
	nil,
	"sword",
	"iron sword",
	"bloodfang sword",
	"godskin sword",
	"moonlight great sword"
}
--ernesto
shields={
	"shield",
	"hero's shield",
	"shield of kings",
	"templar shield",
	"fingerprint shield"
}
--team
map_areas={
	nil,--0
	{"bandit","bandit","skultula","zombie","spider","bat","giant"},
	{"bandit","bandit","skultula","zombie","spider","bat","giant"},
	{"skultula","skultula","skultula","bandit","spider"},
	{"spider","spider","swarm","octork","ooze"},
	{"skultula","skultula","skultula","bandit","spider"},
	{"skultula","skultula","skultula","bandit","spider"},
	{"skultula","skultula","skultula","bandit","spider"},	
	nil,--8
	nil,
	{"skultula","skultula","skultula","bandit","spider"},	
	nil,
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	nil,--16
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	nil,
	{"skultula","skultula","skultula","bandit","spider"},	
	nil,--24
	{"spider","spider","swarm","octork","octork","octork","ooze","bat","bat"},
	{"spider","spider","swarm","octork","octork","octork","ooze","bat","bat"},
	{"scorpion","scorpion","zombie","zombie","octork","octork","demon","dragon"},
	{"scorpion","scorpion","zombie","zombie","octork","octork","demon","dragon"},
	{"skultula","skultula","skultula","bandit","spider"},	
	{"skultula","skultula","skultula","bandit","spider"},	
	nil
}
--team
map_danger={
	0,
	0.1,
	0.1,
	0.05,
	0.1,
	0.05,
	0.05,
	0.05,
	0,
	0,
	0.05,
	0,
	0.05,
	0.05,
	0.05,
	0.05,
	0,
	0.05,
	0.05,
	0.05,
	0.05,
	0.05,
	0,
	0.05,
	0,
	0.1,
	0.1,
	0.15,
	0.15,
	0.05,
	0.05,
	0
}
--ernesto and jared
--all interactive objects
interactive_objects={
	{
		x=123,
		y=60,
		text_before={
			"take this lamp",
			"the night is dark and",
			"full of terrors"
		},
		text_after={
			"remember,the lamp you fool"
		},
		action=function()
		 takeItem("lamp") 
		 sfx(56)
		end,
		sprite_before=7,
		sprite_after=7
	},
	{
		x=124,
		y=3,
		text_before={
			"you found a iron sword!"
		},
		action=function() addWeapon(4) end,
		sprite_before=19,
		sprite_after=20
	},
	{
		x=72,
		y=3,
		action=function() end,
		sprite_before=32,
		sprite_after=17,
		text_before={
			"abandoned ruin"
		}
	},
	{
		x=7,
		y=3,
		action=function() takeItem("shard_left") end,
		sprite_before=19,
		sprite_after=20,
		text_before={
			"you found piece", 
			"of the elden ring!"
		}
	},
	{
		x=109,
		y=45,
		sprite_before=7,
		sprite_after=7,
		text_before={
			"let me heal your wounds!"
		},
		action=heal,
		repeatable=true
	},
	{
		x=31,
		y=22,
		sprite_before=7,
		sprite_after=7,
		text_before={
			"let me heal your wounds!"
		},
		action=heal,
		repeatable=true
	},
	{
		x=49,
		y=36,
		sprite_before=7,
		sprite_after=7,
		text_before={
			"let me heal your wounds!"
		},
		action=heal,
		repeatable=true
	},
	{
		x=98,
		y=46,
		sprite_before=8,
		sprite_after=8,
		text_before={
			"come back with this shield or",
			"on it."
		},
		text_after={
			"go forth and put the shield",
			"to good use!"
		},
		action=function() addArmor(1) end
	},
	{
		x=29,
		y=18,
		sprite_before=8,
		sprite_after=8,
		text_before={
			"yes,i can build you a boat",
			"for 25 gold pieces."
		},
		text_after={
			"i hope this boat serves",
			"you well!"
		},
		action=function(self)
			if plr.gold>=25 then
			
				takeItem("boat")
				plr.gold-=25
				sfx(56)
				active_text={
					"here is your boat,i'll",
					"take the 25 gold pieces."
				}
			else
				self.touched=false
			end
		end
	},
	{
		x=99,
		y=7,
		text_before={
			"the ground here is unusual."
		},
		sprite_before=85,
		sprite_after=86,
		action=function(self)
			if inventory.shovel then
				inventory.cloak=true
				active_text={
					"you found a exiles cloak!"
				}
				sfx(56)
			else
				self.touched=false
				self.text_before={
					"looks like someone has been",
					"digging here."
				}
			end
		end
	},
	{
		x=60,
		y=2,
		sprite_before=8,
		sprite_after=8,
		text_before={
			"i can sell you this shovel",
			"for 10 gold pieces"
		},
		text_after={
			"i hope you dig up something",
			"valuable!"
		},
		action=function(self)
			if plr.gold>=10 then
				takeItem("shovel")
				plr.gold-=10
				sfx(56)
				active_text={
					"here's the shovel, and",
					"i'll take the 10 gold."
				}
			else
				self.touched=false
			end
		end
	},
	{
	 x=53,
	 y=52,
	 sprite_before=34,
	 sprite_after=40,
	 text_before={
	 	"cave of a mad",
		"glintstone sorcerer"
	 },
	 action=function() end
	},

	{
		x=9,
		y=27,
		action=function() takeItem("shard_middle") end,
		sprite_before=19,
		sprite_after=20,
		text_before={
			"you found piece", 
			"of the elden ring!"
		}
	},
		{
		x=0,
		y=32,
		action=function() takeItem("shard_right") end,
		sprite_before=19,
		sprite_after=20,
		text_before={
			"you found piece", 
			"of the elden ring!"
		}
	},
	{
	 x=19,
	 y=02,
	 sprite_before=32,
	 sprite_after=17,
	 text_before={
	 	"ice maze"
	 },
	 action=function() end
	},
	{
	 x=27,
	 y=55,
	 sprite_before=32,
	 sprite_after=17,
	 text_before={
	 	"flooded tunnels"
	 },
	 action=function() end
	},
	{
		x=17,
		y=58,
		sprite_before=85,
		sprite_after=86,
		text_before={
			"the ground here is unusual"
		},
		action=function(self)
			if inventory.shovel then
				addWeapon(5)
				active_text={
					"you found a bloodfang blade!"
				}
				sfx(56)
			else
				self.touched=false
			end
		end
	},
	{
		x=29,
		y=1,
		text_before={
			"you found the shield of the",
			"ancient kings!"
		},
		action=function() addArmor(2) end,
		sprite_before=19,
		sprite_after=20
	},
		
	{
		x=8,
		y=23,
		text_before={
			"you found the",
			"cloranthy ring!"
		},
		action=function() 
			takeItem("ring")
			sfx(56)
		end,
		sprite_before=19,
		sprite_after=20
	},
	{
		x=8,
		y=55,
		text_before={
			""
		},
		action=function() 
			active_text=isEldenWhole() and
			{
				"visions of",
				"mad man"
			} 
		end,
		sprite_before=119,
		sprite_after=117
	},
	{
		x=98,
		y=38,
		text_before={
			"this old pickaxe? you can",
			"have it.maybe it will aid",
			"you in your journey."
		},
		action=function()
			takeItem("pickaxe")
			sfx(56)
		end,
		text_after={
			"have you found any use",
			"for the pickaxe?"
		},
		sprite_before=8,
		sprite_after=8
	},
	{
		x=66,
		y=2,
		text_before={
			"this spot looks unusual"
		},
		action=function(self)
			if inventory.pickaxe then
				active_text={
					"you break the rock with",
					"the pickaxe!"
				}
			else
				self.touched=false
			end
		end,
		sprite_before=71,
		sprite_after=17
	},
	{
		x=49,
		y=62,
		sprite_before=57,
		sprite_after=57,
		text_before={
			"ah you found me",
			"take this shield as",
			"reward!"
		},
		text_after={
			"please leave!"
		},
		action=function()
			addArmor(3)
		end
	},
	{
		x=36,
		y=55,
		text_before={
			"this boulder looks unusual"
		},
		action=function(self)
			if inventory.pickaxe then
				active_text={
					"you find the godskin sword!"
				}
				addWeapon(6)
			else
				self.touched=false
			end
		end,
		sprite_before=87,
		sprite_after=86
	},
	{
		x=22,
		y=16,
		text_before={
			"this spot looks unusual"
		},
		action=function(self)
			if inventory.pickaxe then
				active_text={
					"you break the rock with",
					"the pickaxe!"
				}
			else
				self.touched=false
			end
		end,
		sprite_before=87,
		sprite_after=17
	},
	{
		x=83,
		y=42,
		sprite_before=85,
		sprite_after=86,
		text_before={
			"the ground here is unusual"
		},
		action=function(self)
			if inventory.shovel then
				addWeapon(7)
				active_text={
					"you found a moonlight greatsword!"
				}
				sfx(56)
			else
				self.touched=false
			end
		end
	}
}
--jared
stairs_list={
	{
		--dungeon 1
		from=locationIndex(72,3),
		to=locationIndex(0,15)
	},
	{
		--back
		from=locationIndex(0,15),
		to=locationIndex(72,3)
	},
	{
		--dungeon 4
		from=locationIndex(53,52),
		to=locationIndex(8,63)
	},
	{
		--back
		from=locationIndex(8,63),
		to=locationIndex(53,52)
	},
	{
		--dungeon 2
		from=locationIndex(19,2),
		to=locationIndex(0,16)
	},
	{
		--back
		from=locationIndex(0,16),
		to=locationIndex(19,2)
	},
		{
		--dungeon 3
		from=locationIndex(27,55),
		to=locationIndex(8,39)
	},
	{
		--back
		from=locationIndex(8,39),
		to=locationIndex(27,55)
	},
	{
		--to gold chest
		from=locationIndex(66,2),
		to=locationIndex(27,1)
	},
	{
		--back
		from=locationIndex(27,1),
		to=locationIndex(66,2)
	},
	{
		--to hidden river
		from=locationIndex(22,16),
		to=locationIndex(70,46)
	},
	{
		--back
		from=locationIndex(70,46),
		to=locationIndex(22,16)
	}
}
--jared
dungeon_coords={
	locationIndex(0,0),
	locationIndex(0,16),
	locationIndex(0,32),
	locationIndex(0,48)
}
--lance
dungeon_monsters={
	{8,1,"bandit","t"},
	{1,1,"bandit"},
	{2,1,"bandit"},
	{14,0,"spider"},
	{5,7,"bandit"},
	{15,11,"zombie"},
	{6,15,"skultula","t"},
	{10,14,"zombie"},
	{5,16,"spider"},
	{9,18,"giant"},
	{9,24,"bandit","t"},
	{14,22,"skultula","t"},
	{0,19,"bandit","t"},
	{9,30,"zombie","t"},
	{14,28,"zombie"},
	{1,29,"bandit"},
	{3,23,"giant"},
	{13,37,"swarm"},
	{4,36,"scorpion"},
	{11,33,"spider","t"},
	{2,33,"octork"},
	{5,41,"skultula","t"},
	{6,47,"swarm"},
	{10,47,"swarm"}
}


--team
win_text={
	"you win!"
}

fail_text={
	"you lose!"
}

final_tough_monsters={
	"bat",
	"spider",
	"zombie",
	"octork"
}

final_monsters={
	"demon",
	"dragon",
	"scorpion"
}
-->8
--utils
--jared
function dist(fx,fy,tx,ty)
	local dx,dy=fx-tx,fy-ty
	return sqrt(dx*dx+dy*dy) 
end
--derek
function initTransition()
	t_cover=0
end
--derek
function transitionOut()
	music(-1,300)
	local x,y=map_x*8,map_y*8
	while t_cover<128 do
		rectfill(x,y,x+t_cover,y+127,0)
		t_cover+=4
		flip()
	end
end
--derek
function transitionIn()
	local x,y=map_x*8,map_y*8
	if t_cover>0 then
		rectfill(x,y,x+t_cover,y+127,0)
		t_cover-=4
	end
end
-->8
--ui
--lance and derek
function drawStatusBar()
	local x,y=map_x*8+4,plr.y%16>7 and map_y*8+4 or map_y*8+112
	drawFramedRect(x,y,40,10)
	print("hp: "..plr.hp.."/"..plr.hpmax,x+3,y+3,10)
	framedText("❎:stats",x+86,y+3,6)

end
--erenesto and lance
function drawStats()
	local x,y=map_x*8+4,map_y*8+20
	drawFramedRect(x,y,120,80)
	print("level:  "..plr.lvl,x+3,y+3,6)
	print("xp:     "..plr.xp,x+3,y+9,6)
	print("next:   "..nextLevel(plr.lvl),x+3,y+15,6)
	print("power:   "..plr.atk-2,x+70,y+9,6)
	print("defense: "..plr.def+1,x+70,y+15,6)
	print("gold:    "..plr.gold,x+70,y+3,6)
	
	print("weapon: "..weapons[plr.atk],x+3,y+27,6)
	print("shield: "..shields[plr.def+1],x+3,y+33,6)
	print("items",x+3,y+42,9)
	if inventory.lamp then
		spr(21,x+4,y+52)
	end
	if inventory.boat then
		spr(18,x+19,y+52)		
	end
	if inventory.cloak then
		spr(22,x+34,y+52)		
	end
	if inventory.shovel then
		spr(23,x+49,y+52)		
	end
	if inventory.pickaxe then
		spr(24,x+64,y+52)
	end
	if inventory.ring then
		spr(41,x+79,y+52)
	end
	
	--jared
	if isEldenWhole() then
		--spr(35,x+19,y+70)
		sspr(24,16,8,8,x+56,y+62,16,16)
	else 
		if inventory.shard_left then
			spr(36,x+3,y+70)
		end
		if inventory.shard_middle then
			spr(37,x+19,y+70)
		end
		if inventory.shard_right then
			spr(38,x+36,y+70)
		end
	end
	print("❎",x+110,y+72+sin(time()*2),6)
end
--lance and derek
function drawHPbar(ent)
	if ent.hp>=ent.hpmax then
		return
	end
	local w,wmax=ceil(ent.hp*(8/ent.hpmax)),8
	local x,y=ent.x*8,ent.y*8
	rectfill(x-2,y-5,x+wmax,y-3,0)
	line(x-1,y-4,x+w-1,y-4,7)	
end

-->8
--story progression
--team
function initStory()
	inventory={
		boat=false,
		cloak=false,
		lamp=false,
		shovel=false,
		pickaxe=false,
		ring=false,
		shard_left=false,
		shard_middle=false,
		shard_right=false
	}	
	initInteractiveObjs()
end
--ernesto
function takeItem(item)
		inventory[item]=true
end
--team
function initInteractiveObjs()
	story_map={}
	for obj in all(interactive_objects) do
		local obj_index=locationIndex(obj.x,obj.y)
		mset(obj.x,obj.y,obj.sprite_before)
		story_map[obj_index]=obj
		story_map[obj_index].touched=false
		story_map[obj_index].index=obj_index		
	end
end
--jared
function initStairs()
	stair_map={}
	for stair in all(stairs_list) do
		stair_map[stair.from]=stair.to
	end 
end
--jared
function isEldenWhole()
	return inventory.shard_left and
							 inventory.shard_middle and 
							 inventory.shard_right
end
-->8
--dungeons
--team
function populateDungeons()
	for item in all(dungeon_monsters) do
		local x,y,kind,tough=item[1],item[2],item[3],item[4]
		local make_function=tough and makeToughMonster or makeMonster
		add(monsters,make_function(x,y,monster_types[kind]))
	end
end
--jared
function makeFog()
	fog={}
	for i=1,4 do
		fog[i]={}
		for x=1,16 do
			fog[i][x]={}
			for y=1,16 do
				fog[i][x][y]=true
			end
		end
	end
end
--jared
function isDungeon()
	for i,dun in pairs(dungeon_coords) do
		if locationIndex(map_x,map_y)==dun then
			return i
		end
	end
	return false
end
--jared
function finalDungeon()
	return isDungeon() and map_y>47
end
--jared
function finalDungeonUpdate()
	final_dungeon_turn+=1
	if final_dungeon_turn>=10 then
		final_dungeon_turn=0
		for i=0,1 do
			local tough=rnd()<0.5
			local mon_table=tough and final_tough_monsters or final_monsters
			local make_function=tough and makeToughMonster or makeMonster			
			mon=rnd(mon_table)
			add(monsters,make_function(7+i*2,53,monster_types[mon]))			
		end
	end
end
-->8
--game screens

--team
function initGame()
	setupVars()
 	setupMap()
	makePlayer()
	setupText()
	initStory()
	initStairs()
	makeFog()
	initSpecMonster()
	populateDungeons()
	initTransition()
	initTitle()
end
--team
function setupMap()
 map_x=0
 map_y=0
 player_in_dungeon=false
end
--team
function setupVars()
 stats_mode=drawStatusBar
 monsters={}
 debug={}
 game_over_pos=140

 ring_turn=1

 final_dungeon_turn=0
 
 active_message=""
 message_timer=0
end
--team
function initTitle()
	
	title_cursor=0
	_draw=drawTitle
	_update=updateTitle
end
--lance
function initSpecMonster()
	behemoth=makeMonster(77,53,monster_types.behemoth)
	add(monsters,behemoth)
	dark_lord=makeMonster(8,52,monster_types.darklord)
	add(monsters,dark_lord)
end
--derek
function drawTitle()
	clearScreen()
	spr(72,36,36,8,3)
	spr(120,42,63,8,1)
	shadowText("start",55,80,title_cursor==0 and 10 or 5,title_cursor==0 and 4 or 0)
	transitionIn()
end
--derek
function updateTitle()

	if btnp(❎) or btnp(🅾️) then
		sfx(56)
		
		_draw=drawGame
		_update=updateGame
		transitionOut()
		setCamera()
		
	end
end



--team
function drawGame()
	clearScreen()
	drawMap()
	setCamera()
	drawPlayer()
	drawAllMonsters()
	drawFog()
	unfog()
	drawText()
	stats_mode()	
	drawMessage()
	transitionIn()
end

--team
function drawGameOver()
	clearScreen()
	cls()
	camera()
	spr(9,50,flr(game_over_pos/2),4,2)
end
--team
function updateGameOver()
	game_over_pos=max(100,game_over_pos-1)
	if btnp(❎) or btnp(🅾️) then
		transitionOut()
		initGame()
	end
end
--derek
function drawEnding()
	clearScreen()
	message_x=good_ending and 0 or 3
	end_text=good_ending and win_text or fail_text

	camera()
	for i,letter in pairs(end_message) do
			spr(letter,(i-1+message_x)*8,10)
	end
	for i,txt_line in pairs(end_text) do
		shadowText(txt_line,0,20+i*7,8,5)
	end
	
	transitionIn()
end
--derek
function updateEnding()
	if btnp(❎) or btnp(🅾️) then
		transitionOut()
		initGame()
	end	
end








__gfx__
0000000003333300090909000111004700ff00006055500000ff00000111004700ff000003333300033333003000003003333330033333003000003030000000
00000000533111300999990001f1004400ff0000605f500000ff000001f1004400ff000033111330331113303300033031111110331113303000003030000000
007007000317173009f9f90001f1044003333000605150400555500001f104400cccc00031000110310001303130313030000000310001103000003030000000
000770000311113009fff90011114400f0330f0055111f40f0550f0011114400f0cc0f0030003330300000303013103033330000300000003000003030000000
00077000003313000022200022224000003300000f111f40002200002222400000cc000030001130333333303001003031110000300000003000003030000000
00700700033133300f222f0022222000040040000054504002222000222220000400400033000330311111303000003030000000330003303000003030000000
00000000035153300040400022222000040040000040400022222200222220000400400013333310300000303000003013333330133333101333331033333300
00000000031333300040400044444000000000000040400000000000444440000000000001111100100000101000001001111110011111000111110011111100
4444444455000000000400004a4444a44a4aa4a40005550000000000004440000055500003333300300000300333333033333300000300003333333033300000
4ffffff155000000007400004a4444a4050990500050005000666000000400000555550031111130300000303111111031111130000300003111111055533000
4f1ff1f155055000077400004a4444a4000000000666866600606000000400005004005030000030130003103000000030000030000300003000000033355300
4f1f1ff155055000000400004a4444a400000000006aaa6006600600000400000004000030000030030003003333000033333310000300003333000055333530
4ffffff155055050a0040aa0aaa99aaa05000050006aaa6006000600005550000004000030000030013031003111000031113000000300003111000035533353
4111111155055050a4444400090990904a4444a40069996060006060005550000004000030000030003030003000000030001300000100003000000033553353
0004100055055050044440004a4444a44a4444a4055555550666066000050000000a000013333310001310001333333030000130000300003000000055533353
0004100000000000000000004a4444a44a4444a40000000000000000000000000000000001111100000100000111111010000010000100001000000055333553
04444400660000004444440009999900000990000009900090909009000000004400000000000000000090009900990000000000044444000000033333355533
44fff44066000000400f044090009090900990090099990009090090000000004400000000080000000490800900900000000000044444000003355555555330
4000f040660660004fffff40900009900909909009099090909009000000000044044000099a7000000408000900900000000000000000000035533355533300
4fffff40660660604000f0409900009000999900900990090900900900000000440440009007a800004440009000090006666660004440000353335533333000
40f00040660660604fffff4090900090000990000009900090090090000000004404404090009000044000009000090066666600004440003533355333344490
4fffff400000000040f0004090090090900990090099990000900909000000004404404009009000440000009999990000000000000000003533553344904944
40000040660660600444444009999900090990900909909009009090000000004404404000990000400000000999900006666000044444003533355549449000
00000000000000000000000000000000009999009009900990090909000000000000000000000000000000000000000000000000000000003553335504494400
4000004060555000005550000555550000555500009a000000000000008880004066604000000000005550000007000000555000000000000090900000070000
40555040605f50000585850058555850005115000900000000880000088888004777774009000900058585007777770000585000000000006099906000707000
45555540605850400050500058858850005115509000000000800900868886804707074008888800055055500011017047787740005500006705076000077700
4585854055888f100050500055555550555115509090000000009900866866804777774008080800005050507001117747777740090089006767676000000700
055555000f888f10050505000505050058555550099900000aa00000888688804777774008888800005555507088800047777740509000500767670000700000
40505040005250400005000055555550555258500999aa000a000800888888804066604008888800005850507005550040666040500000500067600077000070
40505040001010000050500050585050555255559090900000008800080008004060604000808000055550500555500040606040095589000007000000000000
40000044001010000000000050050050522222250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033300000000060033555333666066608556666680000000000500000033333003300330000033700000000000073300033333330000333333330000
00000000333003000000000003355555000000005561166688000000005000000333333003300330000033770000000000773300033333330000333333333000
00050000033033300006000000333555606660605661166658200000000005003330000003300330000003370000000000733000033777770000330000033000
00000000000033306000000000033333000000005666666655280000050005003300777003300330000003377000000007733000033000000000330000033000
00000050033033000000006009444333666066605666666665582000500000503307000003300330000000337000000007330000033000000000330000033000
00000000333000000000000044940944000000005666666416552800000000003300000003300330000000337700000077330000033000000000330000033000
05000000330000000600000000094494606660605666666416655820000000003330000003300330000000033700000073300000033000000000330000033000
00000000000000000000000000449440000000005555555466665528000000000333300003300330000000033770000773300000033000000000337777733000
05050500006600000000000000200000665a56600000000050000050006600000033330003300330000000003370000733000000033333330000333333333000
50505050066666000000000000220000009896600001000000500500096669000000333003300330000000003377007733000000033333330000333333330000
05050500666606000000100020200200669990000000010055055500669696000070033003300330000000000337007330000000033777770000333000000000
50505050666666600000000002022000064446600010000000000500666966600007033003300330000000000337777330000000033000000000333300000000
05050500606660600000000000220200664440600000000050000050669696600000033003300330000000000033773300000000033000000000337730000000
50505050666606600001000000020000604446600100000050000500696669600000333003300330000000000033773300000000033000000000330033000000
05050500066666001000000000020000665456000000010005505050066660003333330003300330000000000003333000000000033000000000330077300000
00000000000000000000000000000000066666600000000000000000000000003333300003300333333333000003333000000000033333330000330000330000
c000ccc000000000dd000d000100010066666558100000000dd0ddd0d000ddd00000000000000333333333000000000000000000033333330000330000730000
0ccc00001001000000ddd000101010106611665501001010dd0dd0000ddd00000777000007700777777777000000770000000000077777770000330000033000
0000000001100000000000000100010066116665000001000dddddd0000000000000000000000000000000000000000000000000000000000000770000077000
ccc00cc000001010000000000000000066666665000000000dd0ddd0ddd00dd0000000000000000000000000000aaaa000000000000000000000000000000000
000cc00010000100d0000dd0010001006666666511000000ddddd000000dd000000000000000000000000000aaaa99aaaa000000000000000000000000000000
cc0000c0011000000dddd000101010104666666500010100dd0dddd0dd0000d0000000000000000000000000aaaa99aaaa000000000000000000000000000000
00cccc0000001100000000000100010046666665010110000ddddd0000dddd00000000000000000000000000999aaaa999000000000000000000000000000000
00000000000000000000000000000000455555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700700000700000003000000000000070707005005005000000002500500500333330030000030001331000030001303333300033333000000000000000000
07000000007770000033300000007000700000700050500000000082005050003111113033000030013003100030013003000000311111300000000000000000
00070000077707000033300000000700007070000500050000000285050005003000001031300030013003100030130003000000300000100000000000000000
70000070070007000333330000000000700000705005005000008255500500501333330030130030130000310030300003333300133333000000000000000000
07000000700000700333330000000000007070000500050000028556050005000111113030013030133333310033300003000000011111300000000000000000
00007000700000703303033070000000700000700050500000825561005050003000003030001330311111130030130003000000300000300000000000000000
77000070000000000003000007000000070707005005005002855661500500501333331030000130300000030030013003333300133333100000000000000000
00000000000000000000000000000000000000000000000082556666000000000111110010000010300000030030001301111100011111000000000000000000
56665656665666566656565666565656171704040404040404042424242424242404040404040404140434f234f204444444042404444444444444444434f234
f2140404040404042404040404e2f1e2f1e2f1040404060606040404040404040414141404676404040404046764040404040404041514140404040404041717
5656565666566656665656566656565617040404040404040404040414140404242424240404040414e2f104e2f1e2f1144404240444e2f1e2f1e2f1e2f10414
0404040415040404242404040434f234f234f2040404040606150404040404046764040404544604040404405446040404040404140414141404040404171717
666666566656565666666656665656561704040404042525252525141404040404040424240414141434f20434f234f214440424044434f234f234f234f20404
04041504040414040424242424242424242404041504040606040404040404045446046004040440040404040404046764040414141414141414040404041717
56565656565656565656565656565656170404040404040425252525352525040404040424242424040404e2f1f1e2f11445f724f745e2f1e2f1e2f114040404
04040404041414141414241414040404042424040404040606040404040404040404040404040404040404040404605446041414040415140414140404171717
5656665656566656565666565666665617170404040404252535252525250404040404040404042424242434f2f234f214700424040434f234f234f224242424
04040404040404141414241414040404040424040404040406060404040404040404040404676404040404040404040404040404141414140414140404041717
56566656565666565656665656566656171717040404252504252535042525252504040404040404140424240404040414242424242404040404242424141424
24040404041504040424241404040404040404240404242405050524040404040404040404544604042404040404040404040414140414141414140404041717
56566666666666565656666666666656171717040404040404252525352525252525040404040414041404242424242424240404042424242424241414140404
24240404140404242424040404040404040404242424240606060624240404040404502404042424012404141414040467640414141414041404141404040417
56565656565656561256565656565656171717040404040425250414141404040404040404141404141424242404040414141414042404041414141414140404
04242424242424240404040404040404141414171704040606060604242424242424242424242424242424240414140454460414141414141414140404041717
56666656666666565656666666565656171704040404040404040404041414141404040414141414042424040404040414141414042404041414141414040404
14040404041404041414040404040414141717171717060606060404040404040404045004242424242424240404040404040404040404041404040404041717
56565656565666565656665656565656171704040404040404040404040404040404141414040404242404040404040414141414042404141414141414041414
14140415041414141414140404041414141704040417170606060414140404040404141414140404042424240404500404040404040404040404040404171717
56666666666666665666666666666656171704040404040404141414140404040404140404040424240404040404040414141414042414141414141414041414
14040404141435351414040404141414171704750417170606060414141404040404140424242424040404242424242424240404040404041504040404171776
56565666565656665666565666565656170404040404040404040414141414141414141404042424040404040404040404141414042404141414140414041414
14141414143514141435041717353517171704040417060606060404041414040404042424040424040404040404040404242424040404040404040404040676
56665656565656565656565656566656170404040404040404040414141414141404040404242404040404141404040404040414042424040404141414041414
14141414351717171717171717171717171717061717170606060404040404040414142414041424040404040404040404040424240404041415040404040676
56665666666666665666666666566656171704040404040404041414141414141414042424240404040414041404040404040404040424041417171714040404
04040417171717170606171706061717060606061717060606060404040404040404040404041424044004040430040404040404240404041415141404040676
56565666565656665666565666565656171717170404040414141414141414141414042424040414040414040404140414171717171717171717171717171714
17171717171711040606060606060606061717171725060606040404141404040404400404041424676404040467640404040404042404040414141404040676
56665666565656565656565666566656171717170404141414141414141414141414040404040414141404040404141717171717171717171717171717171717
17171717171717170606061717171717171725252525060606040404140404040404676404040424544604040454460415150404040424040414140404040676
575757575757d2575757d25757575757171717170404141414141414141414141414040404040404040404040417171717252525252517251717172525251717
17171725171735171717171717171717252525252525250606060404040404040404544604042424040404040404040404040404040424242404140404060676
575757575757d257c257d25757575757171704040414140606141414141414141414140404040404040404040414041717252515252525252525252525251717
17172525253517170435352425352525250606252525060606060404040404040404040404042404040414141404041414141415040404042404140606767676
575757575757d2575757d25757575757171414141414060606060606060606061414060604040406040404040404171717172525352525252535252517171717
25042504040404043535252424242506060606060606060604040404040404141414140404242404141414140404041404041414140404042424041404060676
575757575757d2575757d25757575757171714141406060606060606060606060606060604060606060414040404041717252525252525152525251717172525
25252504253525253525252506050606060606060606060604040404040414140404141404240404140404040404141414141414140404040424241414040676
57575757575757575757575757575757171714140606060606060604040606060606060606060606061414040404171725252525252225252525171717172525
04250435353525252525250606050606060606060606060404040414141414040404041424240414040404040414140404141414040404040404241414140676
45444444455757575757575745444445171714140606060606060414140606060606060606060606060606060404171725252525252525253525252517172525
25353525252525252506060606050606060404060606040404040404040404040404040424240404141404041414040415141414040404040414241414060676
44444444444557575757574544444444171714140606060606041404141406060606060404350406060606060404171717252535252525252525171717252525
35352525252525060606060606050624242404040404040404140404040404040404040424240404041414141404140404141404040404141414240404067676
44444444444445575757454444444444171414140606060606141402041406060606060675040406060606060404041717252525252525252517171725252535
35252525060606060606060604242424042404040404040404140406040404040404242424040404040414040414140414141414141414141404042404040676
44444444444444455745444444444444171414060606060606041404141406060606060606060606060606060404041717172525352525251717172525353525
25252506060606060606060404040404042424140404040404140406060604040404042404040404141414040415040414041414041414040404042404060676
44444444444444445744444444444444171714060606060606060414040606060606060606060606060606061404041717171725252525171725253535252525
25060606060606040404040404040404040424242424241414140406060604040404242404040414140404041414141404141414141404040404040404040676
44444444444444445757575757575744171414060606060606060606060606060606060604060606060606141404041717171725252525252535350425252506
06060606060604040404040404040414040404040404242404040404060606040424240404040404040414140414140404040414140404040404040404040676
44444444444444444444444444455744171414060606060606060606060606061406060404060614040406060414041717252525252525252535353525250606
06060606040404040404040404040614140404040404042424040404060606042404040404040404041415151404040404040614140404040404040404040476
44444444444444445757575757445744171414140606060606060606060614141404141414060614140414060604040417252525253525252525352525060676
06040404040404040604040404040606041414040606040424240404040505240404040404040414141404040406060606060606060606040467647004040676
44444444444444445745444457575744171414141406141414140606141414141404040404040404141414040606060617171725252525250606062525250676
76060406060606060606061414067606060414040606060404242424240506040606060404040404040404040406060606060676060606060454460404040676
44444444444444445744444457574544171717141414141717141414141417140404041717170404040404040417170604931717171706060676760606060676
76060676767676767606060606067676060606060676060606060606060606060606060606060606060606060606767676767676767676760606040406060676
44444444444444441244444444444444171717171717171717171717171717171717171717171717171717171717171717171717177676767676767676767676
76767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000ddddd00dd0000dd000000dddd00000ddddddd0000dddddd00000ddddd000000000000000000000000000000000
0000000000000000000000000000000000000dddddd00dd0000dd00000dddddd0000dddddddd000ddddddd000dddddd000000000000000000000000000000000
000000000000000000000000000000000000ddd000000dd0000dd0000ddd00ddd000dd0000ddd00dd000ddd0ddd0000000000000000000000000000000000000
000000000000000000000000000000000000dd00ccc00dd0000dd0000dd0000ddd00dd00000dd00dd0c00dd0dd00ccc000000000000000000000000000000000
000000000000000000000000000000000000dd0c00000dd0000dd000ddd0000ddd00dd00000dd00dd00c0dd0dd0c000000000000000000000000000000000000
000000000000000000000000000000000000dd0000000dd0000dd000dd000000dd00dd00000dd00dd0000dd0dd00000000000000000000000000000000000000
000000000000000000000000000000000000ddd000000dddddddd000dd000000dd00dd00000dd00dd0000dd0ddd0000000000000000000000000000000000000
0000000000000000000000000000000000000dddd0000dddddddd000dddddddddd00dd0000ddd00dd0000dd00dddd00000000000000000000000000000000000
00000000000000000000000000000000000000dddd000dd0000dd000dddddddddd00dddddddd000dd0000dd000dddd0000000000000000000000000000000000
0000000000000000000000000000000000000000ddd00dd0cc0dd000dd000000dd00ddddddd0000dd0000dd00000ddd000000000000000000000000000000000
00000000000000000000000000000000000000c00dd00dd0000dd000dd0cccc0dd00dd000ddd000dd0000dd000c00dd000000000000000000000000000000000
000000000000000000000000000000000000000c0dd00dd0000dd000dd000000dd00dd0c00ddd00dd0000dd0000c0dd000000000000000000000000000000000
00000000000000000000000000000000000000000dd00dd0000dd000dd000000dd00dd00c00dd00dd0000dd000000dd000000000000000000000000000000000
0000000000000000000000000000000000000000ddd00dd0000dd000dd000000dd00dd00000dd00dd000ddd00000ddd000000000000000000000000000000000
000000000000000000000000000000000000dddddd000dd0000dd000dd000000dd00dd00000dd00ddddddd00dddddd0000000000000000000000000000000000
000000000000000000000000000000000000ddddd0000dd0000dd000dd000000dd00dd00000dd00dddddd000ddddd00000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000ccc00000cc0000cc000cc000000cc00cc00000cc000ccccc0000ccc000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000aa00aaa000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000a00a0aa0000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000a00a0a00000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000aa00a00000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000ddddd0000dddddd00ddddd00ddddddd0000d0000d00000d0d00000d00000000000000000000000000000000000
00000000000000000000000000000000000000d0000d00d0000000d00000d0000d0000000d0000dd0000d00d000d000000000000000000000000000000000000
00000000000000000000000000000000000000d00000d0ddd00000d0000000000d0000000d0000d0d000d00d000d000000000000000000000000000000000000
00000000000000000000000000000000000000d00000d0d00000000ddddd00000d0000000d0000d00d00d000d0d0000000000000000000000000000000000000
00000000000000000000000000000000000000d00000d0d0000000000000d0000d0000000d0000d000d0d0000d00000000000000000000000000000000000000
00000000000000000000000000000000000000d0000d00d0000000d00000d0000d0000000d0000d0000dd0000d00000000000000000000000000000000000000
00000000000000000000000000000000000000ddddd0000dddddd00ddddd00000d0000000d0000d00000d0000d00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000aa00aaa0a0a000000aa0aaa0aaa0aaa00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000a0a0a000a0a00000a000a0a0aaa0a0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000a0a0aa00a0a00000a000aaa0a0a0aa000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000a0a0a000aaa00000a0a0a0a0a0a0a0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000a0a0aaa0aaa00000aaa0a0a0a0a0aaa00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055005505500555055505500505055500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000500050505050050005005050505050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000500050505050050005005050505055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000500050505050050005005050505050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055055005050050055505050055055500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009990000009909990999099900000999090900000999099909990099099909900999099009990000009909990000009909990999009909990000000
00000000009090000090009090999090000000909090900000909090909000900009009090900090900900000090909000000090009090909090009000000000
00000000009990000090009990909099000000990099900000999099009900999009009090990090900900000090909900000099909990999090009900000000
00000000009090000090909090909090000000909000900000900090909000009009009090900090900900000090909000000000909000909090009000000000
00000000009090000099909090909099900000999099900000900090909990990099909990999090900900000099009000000099009000909009909990000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000030303030305050000000000000003100005010000000000000000000001051005000000000010000000050101010000000000000000000500000000000500000000010100040000000000000000000100000105000500000000000000002908010001000101000000000000000008010000010001040000000000000001
0101010101010101010100000000000001010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6363636344636363636363546354636371717171717171717171717171717171717171717170717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171716767676767676767676767676767676767676767676767676767676767676767676767676767676767676767
6363636344636363636363636363636371717170707070717171711173737373737171717171717170707070717170704040714040404040407646404040407171717171714040717140407171717171717171606060606767676760606040404067676760606060404040676767674060606760676060606060606760606067
6363636344636363636363446344636371717020707070707070707171737371717071717171717070727270707170707040404040404040404564400840407171714740405140404040414071717171717140404060606067676060604040406060404040404040404040406767404040606760606040404040606060406067
6363636344636363636363446344636371717070707070707070707071717171707070707171707070727270707070707040404040404040404040404040407171717140404040402040414140407171717171404040606060676060606060606040414140404040404040404040404141606060676040514041414040407171
4463544444546363636354446354444471717170727070707070707272717170707070707171707070707070707070707040424040404040404040404040407171717140404040404040404141407171717171404040406060606060404040414140405141414040404040514040414040406060606040404041404040407171
6363636363636363636363446344636371717170727272707070707070727272727070707171717070707070707070404040404040404040404041404040407171714040404041404040404041404071717140404040406060606060404040414051414140514040404040404040414040404060414040404041404040407171
6344444444444444544444446344636371717070727072707070707070707070727272707171717070727272707070717070404042404040414140404040717171714040404141414051404041407171714040404040406060606060404040414140404040404140404040404040414040404060606740404040404040404071
6363636363634463636363636363636371717070727272707070707070707070707070707171717072727272707070717140404040424040414040404040717171714040404141404040404040407171717140404040406060606060404040405140404040405140404040404040414040404041606741404040404040404071
4463444463634463446363446354444471717070707272727070707272707070707070707171717070707272707071717170404040404040404040404071717171714040414141404040405140404071717140406060406060606060404040404040404040404140404040404040404040404041406060414040514040407171
6363636363634463444454446344636371717072727072727270707072727070707070707071717070707070707071717171404040404240404040404071717171404040414040404040404041417171717140404060606060606060404040404051404040514040404040404040404040514040416060414141404040404071
6363634463636363636344636344636371717070727270707070707072727272707070707070717070707070707071717170404040404240404040404071717171404051404040414141404041417171717140404040404060606060404040404141405140414040414141404040404040404040416040404041414140404071
5444444444544463544444636363636371717070707270707070707072707272727070707070707070727270707071717170404040404240404040404071717171714040404040404141404041414171717140404040404060606040404040404041404040414140404040414040404040404060606040404040404040404071
6363636363636363636363636354636371707070707070717070707072707072727070707072727272727070707071717170404040404242424040404071717171714041414040404141404041414171717140404040404060606060606040404041404040404140404040414140404040404060414040414141404040407171
6363634444546344634444446344636371717070717071717070717170707070707070707272707070707070717171717140404040404040424242404071717171404141405140404141404041414141717171404040404060606060406060604060606060414140404040404141404040404041414141414141404040407171
4444634463636344636354446344444471717171717171717171717171717070707070707070717170707070717171717170404040404040404042424242717171414140404040404040404040414171717140404040404040606060404040606060414060606060414040514041404040404040414040404141404040407171
2163634463636344636363636363636371717171717171717171717171717171707070707071717171717070717140704040404040404040404040717142427161614040404061404061404040406161717140404040404040606060604040404040414040404060606041414141404040404040404140404140404040404071
217373747373747373737373737373737171404071713f717170707171717171717171717171714040404040404040404141414141414141414141717141424161616161616161616161616161616161717140404040404040606060604040404040404040404040416060404040404040404040404151404141404040404071
7373737474737473747474737473737371404040707140404040404040404040404041414040404040402e1f2e1f40404141414141414141414141414141424100616161616161616161616161616140404040404040404040406060604040404040404040404040404040404141404040404141404041404040414040404071
747473737373737373737373747474737140404040404040404040764608404040404041414040404040432f432f40444444444444544454444444444441424040406161614061616161406161616140404040404040404040406060604040404040404040404040404040414041404040404141414040514041404040404071
7373737473747474737373737373737371404040764640404040404564404040404040404041414040402e1f2e1f4044545050445050025050445050542e1f4240404040404040404040404040404040404040404040404040606060404040404040414140404040404040414140404040404041404040404141404040407171
737373747373737473747474737474747171714045640340404040404040404040404040404041414040432f432f404444035050505050505050500444432f4240404040404040404040404040404040404040404040404040606060604040404040404041414140514040414140404040405141404040404141414040407171
7374747473737374737473737374737371717140404040404040404242424240404040404040404141402e1f2e1f4044545050445005500550445050542e1f4240404040404040404040404040404040404040404040404040406060604040404040404141404041414141414140404040404041404040414141404040407171
737473737374737373747373737473737171404040404242421042424242420740404041414141404041432f432f404444444444444442444444444444432f4240404040404040404040404040404040404040404040404040606060604040404040414140404040404040414140404040404040414040404141404040404071
7374737373747373737373737374737371717140404040404040420542424240404040404040414141402e1f2e1f4044445004504410424044505050542e1f4240404040404040404040404040404040404040404040404040606060604040404040414140404141404141414140404040404040414040404141404040404071
737373737374737373737373737373737171714076464040404142424042404040404040404040404140432f432f404444505050444042424250500444432f4242404040404040404040404040404040404040404040404060606060404040404040404040404141414141415140404041414140404140404141404040404071
7474747473737374747474747373737371714040456440404142424040404040404040404040414140402e1f2e1f4044444442444440424044505050542e1f2e1f424242404040404040404040404040404040404040406060606060404040404040404040414040404141404040404041404141414141414141404040717171
737373737374747473737374747473737171404004404041424240407646404040404040404040404040432f432f414444404240404042404444444444432f432f2e1f42424240404040404040404040404040404040406060604040404040404040404040414040404141414040404041414140404140404040404040717171
7373737373747373737373737374737371404040404041424240400645644041414040404040404040402e1f2e1f4044444042404004424044500450442e1f2e1f432f40424242424240414140404040404040414141606060414141404040404040404041414040414140404041404040414141414140404040404040407171
747473747374737373737373737473737140404040404042424040404040404040404040404040402e1f432f432f404444404240404042405450505054432f432f2e1f2e1f2e1f41422e1f2e1f2e1f2e1f2e1f414141606060414141414141414040404041404040404141404040414040414141414141404040404040407171
73737374737473737373737373747373717140404040404042424040404040404040404040404040432f2e1f2e1f4044440342424040424044505050442e1f2e1f432f432f432f4142432f432f432f432f432f414140606060604040404141414141404041414140414141414141414040414141404141404040404040717171
737374747374747474737474747473737140404040404040404242424040404140404041404040402e1f432f432f404444404042424242424250505044432f432f412e1f2e1f4141422e1f2e1f2e1f2e1f2e1f404040406060604040404040414141414140404040404040404040404040404041414041404040404071717171
73737473737373737373737373737373717171404040404040404242404040414141414140404040432f2e1f2e1f4044444440424044444444444444442e1f2e1f41432f432f404042432f432f432f432f432f404040606060604040404040414141414140404040404040404040404040404040404041414040404040407171
__sfx__
000d00001802418041180611807118071180711806118061180611805118051180511804118041180411804118041180311803118031180311803118031180211802118021180211802118021180211802118025
010200000c1500c1410c1310c1210c1310c1410c1510c1310c1210c1210c1110c1110c1150c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c100
010d00001811218122181321814218142181421814218142181421814218142181421813218132181321813218132181221812218122181221812218122181221811218112181121811218112181121811218115
010800000401404011040110401104021040210402104021040310403104031040410404104041040510405104051040510404104041040410403104031040310402104021040210402104011040110401104015
01100000180161b0161f0161b016180161b0161f0161b016180161b0161f0161b016180161b0161f0161b016180161b0161f0161b016180161b0161f0161b016180161b0161f0161b016180161b0161f0161b016
010200000c5500c5410c5310c5210c5310c5410c5510c5310c5210c5210c5110c5110c5150c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c500
01100000180161c0161f0161c016180161c0161f0161c016180161c0161f0161c016180161c0161f0161c016180161c0161f0161c016180161c0161f0161c016180161c0161f0161c016180161c0161f0161c016
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0112000021a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0112000023a1023a101fa101fa101ca101ca101ca101ca101fa101fa101fa101fa101fa101fa101fa101fa1021a1021a1021a1021a1021a1021a1021a1021a1021a1021a1021a1021a1021a1021a1021a1021a10
0112000023a1023a101fa101fa101ca101ca101ca101ca101fa101fa101fa101fa101fa101fa101fa101fa1020a1020a1020a1020a1020a1020a1021a1021a1023a1023a1026a1026a1024a1024a1023a1023a10
0110000015c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001c9101c910219102191024910249102191021910249102491021910219101c9101c91021910219101d9101d910219102191024910249102191021910249102491021910219101d9101d9102191021910
0112000018910189101c9101c9101f9101f9101c9101c9101f9101f9101c9101c91018910189101c9101c910139101391017910179101a9101a9101791017910149101491017910179101c9101c9101791017910
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300001c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001501215012150121501215012150121501215012150121501215012150121501215012150121501500000000000000000000000000000000000000000000000000000000000000000000000000000000
011500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0115000021800218001f8001f80021800218002180021800218002180021800218002180021800218002180021800218002180021800218002180021800218002180021800218002180021800218002180021800
011500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011500001310007100131001310009100091000910009100091000910009100091000910009100091000910009100091000910009100091000910009100091000010000102001020010200102001020010200102
01010000176222360026600236002160024600286002460028600246002d600286002d60028600216022160221602216052160021600216002160021600216002160021600216002160021600216002160021600
011500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011500001fe001fe001fe001fe0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c0021c001de001de001de001de001de001de001fe001fe00
0007000008613086110a6110b6210c6210d6210d62110631116311463116631196311d6312064123641276412b6412e651306513165130651306512e6512c6512b6412964126641216311c631176211162110615
010500002815028151281112d1112d1412d1412d1112d1112d1312d1312d1112d1112d1212d1212d1112d11100100001000010000100001000010000100001000010000100001000010000100001000010028100
000300000465004650006000060000600006000060000600236000060000600006002660000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
01020000292532925326253002032625300203002032225300203002032225300203002032025300203002031e25300203002031c253002031b25300203002031a2530520301203152531c203002031125300203
010200002d5202d5212d5212d5212d5212d5112d5112d5112d5112d51535500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000300000f0501205015050190501e050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001a0001a0501a0501a05005000270502605028050290502805027040280302903028020260202801000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000d6500460000600006000a6400460004600006000863005600056000560006620006002460024600036100d600006001160000610006001c6001d6001e60000600006000060000600006000060000600
000300001813017140161401414012140101400e1400b1500a1500915007160061600416003150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000415004150041500515006150081500a1500c1500e1501115014150181501a15000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000200001647013460104600d4600a45008440074400644019440174401540013400104000d400084000240000400004000040000400004000040000400004000040000400004000040000400004000040000400
000100001a2701526012250112500f2400d2400b2400a240092400823007230052300523003220032100020000200002000020000200002000020000200002000020000200002000020000200002000020000200
00030000100700d070080700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c0700d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 08184344
00 09196044
00 0a182044
00 09192144
00 0a1a2244
00 0b1b2344
00 0a1a2244
00 0c192144
00 08182044
00 09192144
00 08182044
00 09192144
00 0a1a2244
00 0b1b2344
00 0a1a2244
02 0c192144
01 0d58200f
04 0e512110
01 1167144f
00 114f1450
01 1116144f
00 11161450
00 11171450
00 111e1450
01 1116144f
00 11161450
00 11171450
02 111e1450
01 1f156044
00 1f156044
01 1f152644
00 1f152744
00 1f152444
02 1f152544
01 292b2d30
04 2a2c2e31

