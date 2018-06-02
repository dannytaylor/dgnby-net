-- title: dog 'n boy
-- author: @xhiggy
-- script: moon

local wall,plat
local c,p,d,f,m
local client
local numplayers
local b,l
local Ani,Player,Boy,Dog,Cam,Map,Action,Button,Lever
stic=0 -- start tic

DEBUG=false
SCENE=1

init=->
	wall={}
	for i=17,17+15
		wall[i]=true
	plat=[49]:true

	b={
		Button(73,9,{65,10,65,9},{})
		Button(138,16,{125,6,125,7,125,8},{})
		-- Button(9,8,{17,8},{0,1})
	}
	l={
		Lever(105,12,{98,13,99,13,100,13,101,13,102,13,103,13,104,13},{90,13,91,13,92,13,89,13})
		-- Lever(8,8,{10,6},{10,7})
	}

	c=Cam(16,32,0,0)
	p=Boy(7*8,7*8,2,2,4)
	d=Dog(11*8,8*8,2,1,0)
	d.f=1
	f=x:p.x,y:p.y
	m=Map!

	-- network stuff
	for i=0,15
		poke(0xff8c+i,0)
	client = 0
	numplayers = 1
	poke(0xff8c,SCENE)

	--init anims
	do
		p\add_a 1,448,1,0 -- idle
		p\add_a 2,480,8,6 -- walk
		p\add_a 3,450,1,0 -- jump
		p\add_a 4,452,1,0 -- stay
		p\add_a 6,456,2,15  -- come
		p\add_a 5,454,1,0  -- kick
		p\swap_a(1)
	do
		d\add_a 1,416,2,10,2,2 -- idle
		d\add_a 2,420,2,12,2,2 -- walk
		d\add_a 3,386,1,0,2,2 -- jump
		d\add_a 5,388,2,15,2,2  -- wall
		d\add_a 4,392,2,20,2,2  -- stay
		d\swap_a 1

--map collision check
coll=(x,y,t)->
	if t==1
		wall[mget((x)//8,(y)//8)]
	elseif t==3
		plat[mget((x)//8,(y)//8)]
	elseif t==4
		slider[mget((x)//8,(y)//8)]
	elseif t==6
		button[mget((x)//8,(y)//8)]

lerp=(a,b,t)->
	(1-t)*a + t*b
pr=(s,x,y,col)->
	col= col or 6
	print s,x*8+c.xx,y*8+c.yy,col
dbg=->
	if DEBUG
		print 'p ('..p.x//8..','..p.y//8..')',0,0,5
		-- print '('..p.x..','..p.y..')',64,0,5
		print 'd ('..d.x//8..','..d.y//8..')',0,8,5
		-- print '('..d.x..','..d.y..')',64,8,5

class Ani
	new:(b,n,r,w,h)=>		
		@alpha=0
		@scale=1
		@tic=0
		@b,@n,@r,@w,@h=b,n,r,w,h
		@id=@b
	update:=>
		@tic+=1
		if @r!=0 and @tic==@r
			@tic=0
			@id=@id+@w
			if @id==(@b+@w*@n)
				@id = @b
	draw:(x,y,f,ox,oy)=>
		spr(@id,x+c.xx+ox,y+c.yy+oy,@alpha,@scale,f,0,@w,@h)

class Action
	new:(x1,y1,v,w)=>
		@x1,@y1,@v,@w=x1,y1,v,w
		@p=0

class Button extends Action
	new:(x1,y1,v,w)=>
		super x1,y1,v,w
		@id1,@id2=65,30
		@pp=@p
		for i=1,#@v
			if i%2==0
				mset(@v[i-1], @v[i], @id2)
		for i=1,#@w
			if i%2==0
				mset(@w[i-1], @w[i], 0)
	cc:(x1,y1,x2,y2)=>
		p.oy,d.oy=0,0
		if @x1==x1//8 and @y1==y1//8
			@p=1
			p.oy=-2
			if @pp != @p then sfx 1,49,-1,0,5
		elseif @x1==x2//8 and @y1==y2//8 
			@p=1
			d.oy=-2
			if @pp != @p then sfx 1,49,-1,0,5
		else 
			@p=0
	ccc:(x,y)=>
		x=x//8
		y=y//8
		for i=0,2
			for j=0,2
				for k=1,#@v
					if k%2==0
						if @v[k-1]==x+i and @v[k]==y+j then return false
		return true

	update:=>
		pp=@p
		@cc p.x+8,p.y+8,d.x+8,d.y
		if @pp != @p
			if @p==0 and @ccc(p.x,p.y) and @ccc(d.x,d.y)
				for i=1,#@v
					if i%2==0
						mset(@v[i-1], @v[i], @id2)
						@pp=@p
			elseif @p==1
				for i=1,#@v
					if i%2==0
						mset(@v[i-1], @v[i], 0)
						@pp=@p

	draw:=>
		spr(@id1+@p,8*@x1+c.xx,8*@y1+c.yy,0,1,0,0,1,1)

class Lever extends Action
	new:(x1,y1,v,w)=>
		super x1,y1,v,w
		@id1,@id2=67, 49
		@switch=0
		@state=0
		for i=1,#@v
			if i%2 == 0
				mset(@v[i-1], @v[i], @id2*@p)
		for i=1,#@w
			if i%2 == 0
				mset(@w[i-1], @w[i], @id2*math.abs(@p - 1))
	cc:(x,y)=>
		x=x//8
		y=y//8
		if (@x1==x and @y1==y) or (@x1==x-1 and @y1==y) or (@x1==x+1 and @y1==y)
			return true
		return false

	update:=>
		if client==1
			if @cc p.x+8,p.y+8
				if (btnp(5) and p.vy==0 and p.lock<0) 
					@switch=1
					@state=math.abs(@state-1)
					poke(0xff8c+2,@state)
					p.vx=0
					p.vy=0
					p.lock=20
					p\swap_a(5)
		else if (peek(0xff8c+10) != @state)
			@state = math.abs(@state-1)
			@switch = 1
		if @switch==1
			@switch = 0
			@p = math.abs(@p - 1)
			sfx 0,49,-1,0,5
			for i=1,#@v
				if i%2==0
					mset(@v[i-1], @v[i], @id2*@p)
			for i=1,#@w
				if i%2 == 0
					mset(@w[i-1], @w[i], @id2*math.abs(@p - 1))
	draw:=>
		spr(@id1,8*@x1+c.xx,8*@y1+c.yy,0,1,@p,0,1,1)




class Player
	@wall=false
	new:(x,y,w,h,m)=>
		@x,@y,@w,@h,@m=x,y,w,h,m
		@vx,@vy=0,0
		@a=1
		@ani={}
		@ox,@oy=0,0
		@lock=-1
		@button=false
		@f=0
	cc:=> -- collision check
		ww,hh=8*@w-1,8*@h-1
		xx,xy=@x+@vx,@y+@vy

		
		-- horizontal coll
		if coll(xx+@m,xy,1) or coll(xx+ww-@m,xy,1)	or			-- tl,tr
		coll(xx+@m,xy+hh,1) or coll(xx+ww-@m,xy+hh,1) or		-- bl,br
		coll(xx+@m,xy+hh/2,1) or coll(xx+ww-@m,xy+hh/2,1)		-- cl,cr
			@vx=0
		-- vert coll
		if coll(@x+@m,hh+1+xy,1) or coll(@x+ww-@m,hh+1+xy,1) or	-- bl,br
		coll(@x+ww-@m,xy+1,1) or coll(@x+@m,xy+1,1) or	 		-- tr,tl
		coll(@x+8-@m,hh+1+xy,1) or coll(@x+8-@m,xy+1,1)			-- bc,tc
			if @vy!=0
				@wall=false
				@vy=0
			else @y=@y//1
		-- gravity
		elseif @vy<4
			@vy+=0.2
		-- one way platform
		if @vy>=0
			if coll(@x+@m,hh+1+xy,3) or coll(@x+ww-@m,hh+1+xy,3) or coll(@x+8-@m,hh+1+xy,3) -- plats
				if not coll(@x+8-@m,hh-3+xy,3)
					@vy=0
		
	update:=>
		@cc!
		@x+=@vx
		@y+=@vy
		@ani[@a]\update!
	draw:=>
		-- if @button then spr(66, 8*(@x//8)+c.xx,8*(@h+@y//8)+c.yy, 0, 1, 0, 0, 1, 1)
		@ani[@a]\draw @x,@y,@f,@ox,@oy
		-- if @a!=3
		-- 	line @x+@m+c.x, @y+@h*8+c.y, @x+@w*8-@m+c.x,@y+@h*8+c.y, 0
	swap_a:(str)=>
		if @a!=str	
			@a=str
			@ani[@a].tic=0
			@ani[@a].id=@ani[@a].b
	add_a:(str,b,n,r,w,h)=>
		w=w or @h
		h=h or @h
		@ani[str]=Ani(b,n,r,w,h)

class Boy extends Player
	update:=>
		if client==1
			f.x,f.y=@x+32*(1-2*@f),@y
			@input!
			poke(0xff8c+4,math.floor(@x/256))
			poke(0xff8c+5,@x%256)
			poke(0xff8c+6,math.floor(@y/256))
			poke(0xff8c+7,@y%256)
			poke(0xff8c+3,@a)
		else
			tmpx = @x
			@x = peek(0xff8c+12)*256+peek(0xff8c+13)
			@y = peek(0xff8c+14)*256+peek(0xff8c+15)
			if @x ~= tmpx 
				if @x>tmpx then @f = 0 else @f = 1
			tmpa = peek(0xff8c+11)
			if (tmpa>0 and tmpa<6)
				@a = tmpa
				@swap_a(@a)
		super!

	input:=>
		if @lock<0
			if btn 2
				@vx=-1
				@f=1
				@a=2
			elseif btn 3
				@vx=1
				@f=0
				@a=2
			else 
				@vx=0
				@a=1
			if @vy==0 and btnp(0)
				@vy=-2.8
				sfx 2,49,-1,0,5
			-- if  btnp(4) and @vy==0
			-- 	@lock=30
			-- 	@vx=0
			-- 	d.stay=not d.stay
			-- 	if d.stay
			-- 		@a='stay'
			-- 	else 
			-- 		@a='come'
			-- 	if d.x>@x then	@f=0 -- look at dog
			-- 	else @f=1
			if @vy!=0
				@a=3
			@swap_a(@a)
		else @lock-=1

class Dog extends Player
	@stay:false
	update:=>
		if client==2
			f.x,f.y=@x+32*(1-2*@f),@y
			@input!
			poke(0xff8c+4,math.floor(@x/256))
			poke(0xff8c+5,@x%256)
			poke(0xff8c+6,math.floor(@y/256))
			poke(0xff8c+7,@y%256)
			poke(0xff8c+3,@a)
		else
			tmpx = @x
			@x = peek(0xff8c+12)*256+peek(0xff8c+13)
			@y = peek(0xff8c+14)*256+peek(0xff8c+15)
			if @x ~= tmpx 
				if @x>tmpx then @f = 0 else @f = 1
			tmpa = peek(0xff8c+11)
			if (tmpa>0 and tmpa<6)
				@a = tmpa
				@swap_a(@a)
		super!	
	input:=>
		if @lock<0
			if btn 2
				@vx=-1.3
				@f=1
				@a=2
			elseif btn 3
				@vx=1.3
				@f=0
				@a=2
			else 
				@vx=0
				@a=1
			if @vy==0 and btnp(0)
				@vy=-2
				sfx 2,56,-1,0,5
			if @vy!=0
				@a=3
			@swap_a(@a)
		else @lock-=1
	follow:(x,y)=>
		@wall=false
		if @x>x then 
			@f=1
		elseif @x<x
			@f=0
		if not @stay
			@wall=true
			if @x>x+32
				if @x>x+72 then @vx=lerp(@vx,-1.6,0.08)
				else @vx=lerp(@vx,-1,0.08)
			elseif @x<x-32
				if @x<x-72 then @vx=lerp(@vx,1.6,0.08)
				else @vx=lerp(@vx,1,0.08)
			else
				@vx=lerp(@vx,0,.08)
				if math.abs(@vx)<0.2 then @vx=0
				@wall=false
	-- dwall:=>
	-- 	df=20-24*@f
	-- 	if @vy==0 and not @stay and @wall and 
	-- 	coll(@x+df,@y,1) and coll(@x+df,@y,1) and -- wall infront
	-- 	not coll(@x,@y-8,1) and not coll(@x+16,@y-8,1) and
	-- 	not coll(@x+df,@y-8,1)
	-- 		@vy=-2
	-- 		sfx 2,56,-1,0,5
	cc:=>
		-- @follow(p.x,p.y)
		if client==2
			super!
			if @vx!=0 then @wall=false
			-- @dwall!
			if @stay then @vx=0
			if @vy!=0
				@swap_a(3)
			elseif @vx!=0
				@swap_a(2)
			elseif @stay
				@swap_a(4)
			elseif @wall
				@swap_a(5)
			else 
				@swap_a(1)
	draw:=>
		@oy-=8
		super!

class Cam
	new:(x,y,xx,yy)=>
		@x,@y,@xx,@yy=x,y,xx,yy
		@xxx,@yyy=0,0
	update:=>
		@x=math.min(120,lerp(@x,120-f.x,0.03))
		@y=math.min(60,lerp(@y,72-f.y,0.03))
		@xx,@yy=@x//1,@y//1
		@xxx=(@x//8+(@x%8==0 and 1 or 0))+1
		@yyy=(@y//8+(@y%8==0 and 1 or 0))+1

class Map
	new:=>
	draw:=>
		map -c.xxx,-c.yyy,31,18,(c.x%8)+111-15*8,(c.y%8)+55-8*8
		-- do
		-- 	pr('LEFT/RIGHT',6,5)
		-- 	pr('to move',6,6)
		-- 	pr('UP to jump',29,4)
		-- 	pr('some holes you',51,7)
		-- 	pr('can\'t fit in',51,8)
		-- 	pr('some doggo',74,3)
		-- 	pr('can\'t',74,4)
		-- 	pr('doggo can\'t jump v high',88,26)
		-- 	pr('DOWN to crouch',123,14)
		-- 	pr('and look down',123,15)
		-- 	pr('Z will tell',140,8)
		-- 	pr('doggo to stay',140,9)
		-- 	pr('Z will also tell',176,8)
		-- 	pr('doggo to come',176,9)
		pr('test room',6,31)






-------------------------
init!
update=->
	if SCENE==1 -- main menu
		stic+=1
		client = peek(0xff8c+1)
		if stic>=80 then stic=0
		if client == 0 
			cclient = peek(0xff8c+1)
			if cclient == 1 then client = 1
			if cclient == 2 then client = 2
		else if client == 1
			if peek(0xff8c+9)==2 then numplayers = 2
		else if (client == 2 and peek(0xff8c+8)==2) 
			SCENE=2
			sfx 5,48,-1,0,5
		if btn 4
			if numplayers == 2
				SCENE=2
				poke(0xff8c,2)
				sfx 5,48,-1,0,5
	else if SCENE==2
		c\update!
		p\update!
		d\update!

		for bt in *b
			bt\update!
		for lv in *l
			lv\update!


draw=->
	cls 0
	if SCENE==1
		map(210, 16, 30, 17,0,0,0,1)
		if stic<50
			if client == 0 then print('HOST OR JOIN', 94,120,6)
			else if client == 1
				if numplayers == 1 print('WAITING ON A FRIEND', 70,120,6)
				if numplayers == 2 print('\'Z\' TO START', 94,120,6)
			else if client == 2 then print('WAITING FOR HOST TO START', 62,120,6)
	else if SCENE==2
		m\draw!

		for bt in *b
			bt\draw!
		for lv in *l
			lv\draw!

		p\draw!
		d\draw!


		dbg!

gpio_read=->
	for i=8,15
		peek(0xff8c+i)

-------------------------



export TIC=->
	update!
	gpio_read!
	draw!