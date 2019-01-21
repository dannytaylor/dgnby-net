-- title: tic80 networking test
-- author: @xhiggy
-- script: moon

---- globals
export ^
export *
local scene

-- network vars
local lcode, lindex,lock -- lobby code,lcode char index
local byte1,byte2 -- state byte
local client -- none,host,join
local connected,conn_sel

-- classes
local Ani,Player,Boy,Dog,Cam,Map

---- init funct
init=->
	scene = 0
	for i=0,15
		poke(0xff8c+i,0)
	connected = 0
	conn_sel = 0
	client = 0
	lcode = {0,0,0,0}
	lindex = 1
	byte1 = {0,0,0,0,0,0,0,0}
	byte2 = {0,0,0,0,0,0,0,0}

---- classes
-- animation
class Ani
	new:(b,n,r,w,h)=> -- ??anim id, start sprite, #frames, w,h
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
class Player
	@wall=false
	new:(x,y,w,h,m)=> -- start x,y,w/h in spr, 
		@x,@y,@w,@h,@m=x,y,w,h,m
		@vx,@vy=0,0
		@a=1 -- start anim id
		@ani={} -- list of anims
		@ox,@oy=0,0 -- draw offset
		@lock=-1 -- anim/input lock
		@button=false -- is on button
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
		@ani[@a]\draw @x,@y,@f,@ox,@oy
	swap_a:(id)=> -- change anim to
		if @a!=id	
			@a=id
			@ani[@a].tic=0
			@ani[@a].id=@ani[@a].b
	add_a:(id,b,n,r,w,h)=> -- create anim
		w=w or @h
		h=h or @h
		@ani[id]=Ani(b,n,r,w,h)

	new:(x,y,xx,yy)=>
		@x,@y,@xx,@yy=x,y,xx,yy
		@xxx,@yyy=0,0
	update:=>
		@x=math.min(120,lerp(@x,120-f.x,0.03))
		@y=math.min(60,lerp(@y,72-f.y,0.03))
		@xx,@yy=@x//1,@y//1
		@xxx=(@x//8+(@x%8==0 and 1 or 0))+1
		@yyy=(@y//8+(@y%8==0 and 1 or 0))+1

---- network helpers
export byte2bits=(val)->
	bits = {}
	if val
		for i=1,8
			rest = math.fmod(val,2)//1
			bits[i]=rest
			val=(val-rest)/2
	bits

export bits2byte=(bits)->
	val = 0
	for i=8,1,-1
		val+=bits[i]*math.pow(2,i-1)
	val

export gpio_read=->
	byte2 = byte2bits(peek(0xff8c+8))
	for i=9,15
		peek(0xff8c+i)
	if byte2[8]==1 then scene = 2

---- draw helpers
prs=(s,x,y,col)-> -- print string to map
	col= col or 6
	print s,x*8+c.xx,y*8+c.yy,col

---- main updates
-- main menu update
u_menu=->
	if client==0 -- not hosted/joined lobby
		if (btnp(2) or btnp(3)) then conn_sel = math.abs(conn_sel-1)
		if btnp(5)
			client = 1+conn_sel
			byte1[3+conn_sel]=1
			poke(0xff8c,bits2byte(byte1))
			lock = 50
	if ((connected == 0) and (peek(0xff8c+8) != 0)) 
		connected = 1
	if client==1 -- if we're hosting
		if lcode[1]==0
			for i=1,3
				lcode[i]=peek(0xff8c+12+i)
		if connected == 1
			if btnp(5)
				scene = 1
				byte1[1] = 1
				poke(0xff8c,bits2byte(byte1))
	else if client==2 -- if joining
		if connected == 0
			if btnp 2
				lindex = (lindex+1)%3+1
			if btnp 3
				lindex = (lindex%3)+1
			if btnp 0
				lcode[lindex] = (lcode[lindex]+25)%26
			if btnp 1
				lcode[lindex] = (lcode[lindex]+1)%26
			if (btnp(5) and lock==0)
				for i=1,3
					poke(0xff8c+12+i,lcode[i]+65)
			if lock > 0 then lock-=1
		else
			if byte2[1]==1 then scene=1
u_game=->

---- draw functions
-- main menu update
d_menu=->
	if client == 0
		tri 26+40*conn_sel,10,34+40*conn_sel,10,30+40*conn_sel,14,15
		print 'host', 20,20,15
		print 'join', 20+40,20,15
	else if client == 1
		if connected == 0
			print 'ur lobby code', 20,20,15
			tri 17,42,12,40,12,44,15
			print string.char(lcode[1],lcode[2],lcode[3]), 20,40,15
			print 'wait 4 friend', 20,60,15
		else
			print 'friend connected', 20,20,15
			print '\'x\' to start', 20,40,15
	else if client == 2
		if connected == 0
			print 'enter lobby code', 20,20,15
			tri 13+6*lindex,30,18+6*lindex,30,15+6*lindex,34,15
			print string.char(lcode[1]+65,lcode[2]+65,lcode[3]+65),20,40,15
		else
			print 'waiting on host', 20,20,15

d_game=->
	print 'game started', 20,20,15

d_disconnect=->
	print 'player disconnected', 20,20,15	

---- main loops
init!
update=(val)->
	if val == 0 
		u_menu! 
	else if val == 1 
		u_game!
draw=(val)->
	cls(0)
	if val == 0 
		d_menu! 
	else if val == 1 
		d_game!
	else if val == 2 
		d_disconnect!
export TIC=->
	update scene
	gpio_read!
	draw scene