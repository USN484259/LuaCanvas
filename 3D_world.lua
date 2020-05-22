local canvas3D = require('canvas3D')

local c3d = canvas3D:new()

local function pt_equ(a,b)
	if a[1] == b[1] and a[2] == b[2] and a[3] == b[3] then return true end
end

local function pt_mov(p,f)
	return {p[1]+f[1],p[2]+f[2],p[3]+f[3]}
end

local function cube(p,d)
	if not d then d = 100 end
	local pt = {
		{-d,-d,-d},
		{-d,-d,d},
		{-d,d,-d},
		{-d,d,d},
		{d,-d,-d},
		{d,-d,d},
		{d,d,-d},
		{d,d,d}
	}

	local surfaces = {
		{pt[1],pt[3],pt[7],pt[5]},
		{pt[2],pt[6],pt[8],pt[4]},
		{pt[1],pt[2],pt[4],pt[3]},
		{pt[5],pt[7],pt[8],pt[6]},
		{pt[1],pt[5],pt[6],pt[2]},
		{pt[7],pt[3],pt[4],pt[8]}

	}
	for _,s in pairs(surfaces) do
		local cur = {}
		for k,v in pairs(s) do
			--cur[k] = {v[1]+p[1],v[2]+p[2],v[3]+p[3]}
			cur[k] = pt_mov(v,p)
		end
		c3d:surface(cur,{pen = 0,brush = 0x00FFFF})

	end

end

local function deg2pt(pitch,yaw,r)
	pitch = math.rad(pitch)
	yaw = math.rad(yaw)
	local s = math.sin(pitch)
	return {r*s*math.cos(yaw),r*s*math.sin(yaw),r*math.cos(pitch)}

end

local function sphere(p,r,d)
	if not r then r = 100 end
	if not d then d = 15 end
	local pitch,yaw
	for pitch = d,180,d do
		for yaw = d,360,d do
			local cur = {
				pt_mov(p,deg2pt(pitch,yaw,r)),
				pt_mov(p,deg2pt(pitch-d,yaw,r)),
				pt_mov(p,deg2pt(pitch-d,yaw-d,r)),
				pt_mov(p,deg2pt(pitch,yaw-d,r))
			}
			if pt_equ(cur[1],cur[4]) then
				table.remove(cur,4)
			end
			if pt_equ(cur[2],cur[3]) then
				table.remove(cur,3)
			end
			c3d:surface(cur,{pen = 0,brush = 0xFFFFFF})
		end
	end

end


local function cylinder(p,r,h,d)
	if not r then r = 100 end
	if not h then h = 200 end
	if not d then d = 15 end
	local yaw
	for yaw = d,360,d do
		local cur = {
			pt_mov(p,{r*math.cos(math.rad(yaw-d)),r*math.sin(math.rad(yaw-d)),-h/2}),
			pt_mov(p,{r*math.cos(math.rad(yaw)),r*math.sin(math.rad(yaw)),-h/2}),
			pt_mov(p,{r*math.cos(math.rad(yaw)),r*math.sin(math.rad(yaw)),h/2}),
			pt_mov(p,{r*math.cos(math.rad(yaw-d)),r*math.sin(math.rad(yaw-d)),h/2})
		}
		c3d:surface(cur,{pen = 0,brush = 0x00FF00})
		local bottom = {
			cur[2],cur[1],
			pt_mov(p,{0,0,-h/2})
		}
		local top = {
			cur[4],cur[3],
			pt_mov(p,{0,0,h/2})
		}
		c3d:surface(top,{pen = 0,brush = 0x00FF00})
		c3d:surface(bottom,{pen = 0,brush = 0x00FF00})

	end
end


local function cone(p,r,h,d)
	if not r then r = 100 end
	if not h then h = 200 end
	if not d then d = 15 end
	local yaw
	for yaw = d,360,d do
		local cur = {
			pt_mov(p,{r*math.cos(math.rad(yaw-d)),r*math.sin(math.rad(yaw-d)),-h/2}),
			pt_mov(p,{r*math.cos(math.rad(yaw)),r*math.sin(math.rad(yaw)),-h/2}),
			pt_mov(p,{0,0,h/2})
		}
		local bottom = {
			cur[2],cur[1],
			pt_mov(p,{0,0,-h/2})
		}
		c3d:surface(cur,{pen = 0,brush = 0x0000FF})
		c3d:surface(bottom,{pen = 0,brush = 0x0000FF})
	
	end
end


local camera
local redraw


local function axis()
--[[
	for _,l in pairs(axis_line) do
		local a = d3d.point(l[1])
		local b = d3d.point(l[2])
		gdi.line(round(a),round(b),{pen = l[3]})
	end
	--]]
	local c = c3d:camera({focus = 0,trunc = false,overlay = true})
	
	c3d:line(camera.pos,{camera.pos[1]+100,camera.pos[2],camera.pos[3]},{0xFF,0x60,0x60})
	--d3d.line(camera.pos,{camera.pos[1]-10000,camera.pos[2],camera.pos[3]},{0xFF,0,0})
	
	c3d:line(camera.pos,{camera.pos[1],camera.pos[2]+100,camera.pos[3]},{0x60,0xFF,0x60})
	--d3d.line(camera.pos,{camera.pos[1],camera.pos[2]-10000,camera.pos[3]},{0,0xFF,0})

	c3d:line(camera.pos,{camera.pos[1],camera.pos[2],camera.pos[3]+100},{0x60,0x60,0xFF})
	--d3d.line(camera.pos,{camera.pos[1],camera.pos[2],camera.pos[3]-10000},{0,0,0xFF})
	
	c3d:camera(c)
end



local function draw()
	
	gdi.fill()

	c3d:camera(camera)
	
	local funs = {
		function() cube({120,-120,0}) end,
		function() sphere({120,120,0}) end,
		function() cylinder({-120,120,0}) end,
		function() cone({-120,-120,0}) end
	
	}
	
	if math.sin(camera.yaw) >= 0 then
		if math.cos(camera.yaw) >= 0 then
			funs[1],funs[2] = funs[2],funs[1]
		else
			funs[1],funs[3] = funs[3],funs[1]
			funs[3],funs[4] = funs[4],funs[3]
		end
	else
		if math.cos(camera.yaw) >= 0 then
			funs[3],funs[4] = funs[4],funs[3]
		else
			funs[2],funs[4] = funs[4],funs[2]
			funs[1],funs[2] = funs[2],funs[1]
		end
	end
	
	
	for i = 1,#funs,1 do
		funs[i]()
	end
	
	
	local str = "pos "..camera.pos[1]..' '..camera.pos[2]..' '..camera.pos[3]
	gdi.text({-400,300},str)
	str = "view "..camera.pitch..' '..camera.yaw..' '..camera.focus
	gdi.text({-400,280},str)

	-- c3d:line({-50,0,0},{-50,0,10000},0)
	-- c3d:line({50,0,0},{50,0,10000},0)
	
	axis()
	gdi.text({-400,-280},"操作说明：WASDRF移动视角，方向键旋转视角，空格重置视角")
	
	return true
end

local function init()
	camera = {
		pos = {-100,-100,200},
		pitch = math.pi/4,
		yaw = math.pi/4,
		focus = 0,	--1,
		trunc = true
	}
	return draw()
end


local function camera_move(k)
	if k == "R" then
		camera.pos[3] = camera.pos[3] + 20
	elseif k == "F" then
		camera.pos[3] = camera.pos[3] - 20
	elseif k == "Z" then
		camera.focus = camera.focus * 0.8
	elseif k == "X" then
		camera.focus = camera.focus / 0.8
	else
		local x = 0
		local y = 0
		if k == "W" then
			x = 20 * math.cos(camera.yaw)
			y = 20 * math.sin(camera.yaw)
		elseif k == "S" then
			x = -20 * math.cos(camera.yaw)
			y = -20 * math.sin(camera.yaw)
		elseif k == "A" then
			x = 20 * math.cos(camera.yaw + math.pi/2)
			y = 20 * math.sin(camera.yaw + math.pi/2)
		elseif k == "D" then
			x = 20 * math.cos(camera.yaw - math.pi/2)
			y = 20 * math.sin(camera.yaw - math.pi/2)
		end
		camera.pos[1] = camera.pos[1] + x
		camera.pos[2] = camera.pos[2] + y
	end
end


local function message(k,t)
	if not t then return end
	if not camera then return end
	if string.find("WASDRFZX",k) then
		camera_move(k)
	elseif k == "up" then
		camera.pitch = math.min(math.pi,camera.pitch + math.pi/90)
	elseif k == "down" then
		camera.pitch = math.max(0,camera.pitch - math.pi/90)
	elseif k == "left" then
		camera.yaw = camera.yaw + math.pi/90
	elseif k == "right" then
		camera.yaw = camera.yaw - math.pi/90
	elseif k == ' ' then
		return init()
	else
		return
	end

	return draw()
	
end


local function entry(msg,arg)
	if msg == "draw" and not arg then
		return init()
	end
	
	return message(msg,arg)


end



return entry,{
	size = {800,600},
	brush = 0xFFFFFF,
	axis = "world",
	interactive = true
}