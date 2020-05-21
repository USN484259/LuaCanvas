local canvas3D = require('canvas3D')

local c3d = canvas3D:new()

local pt = {
	{-100,-100,-100},
	{-100,-100,100},
	{-100,100,-100},
	{-100,100,100},
	{100,-100,-100},
	{100,-100,100},
	{100,100,-100},
	{100,100,100}
}

--[[

local shape = {
	{pt[1],pt[2]},
	{pt[1],pt[3]},
	{pt[1],pt[5]},
	{pt[4],pt[3]},
	{pt[4],pt[2]},
	{pt[4],pt[8]},
	{pt[6],pt[2]},
	{pt[6],pt[5]},
	{pt[6],pt[8]},
	{pt[7],pt[3]},
	{pt[7],pt[5]},
	{pt[7],pt[8]}

}


local function cube(p)
	local combine = function(a,b)
		return {a[1]+b[1],a[2]+b[2],a[3]+b[3]}
	end
	for _,l in pairs(shape) do
		d3d.line(combine(l[1],p),combine(l[2],p),0)
	end
end
--]]


local surfaces = {
	{pt[1],pt[3],pt[7],pt[5]},
	{pt[2],pt[6],pt[8],pt[4]},
	{pt[1],pt[2],pt[4],pt[3]},
	{pt[5],pt[7],pt[8],pt[6]},
	{pt[1],pt[5],pt[6],pt[2]},
	{pt[7],pt[3],pt[4],pt[8]}

}

local function cube(p)
	for _,s in pairs(surfaces) do
		local cur = {}
		for k,v in pairs(s) do
			cur[k] = {v[1]+p[1],v[2]+p[2],v[3]+p[3]}
		end
		c3d:surface(cur,{pen = 0,brush = 0x00FFFF})

	end

end

local camera = {}
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
	
	
	local x,y
	
	-- for y = -2,2,1 do
		-- for x = -2,2,1 do
			-- cube({x*200,y*200,0})
		-- end
	-- end
	
	cube({0,0,0})
	
	
	local str = "pos "..camera.pos[1]..' '..camera.pos[2]..' '..camera.pos[3]
	gdi.text({-400,300},str)
	str = "view "..camera.pitch..' '..camera.yaw..' '..camera.focus
	gdi.text({-400,280},str)

	-- c3d:line({-50,0,0},{-50,0,10000},0)
	-- c3d:line({50,0,0},{50,0,10000},0)
	
	axis()
	
	return true
end

local function init()
	camera = {
		pos = {100,100,200},
		pitch = math.pi/4,
		yaw = math.pi/4,
		focus = 0,	--1,
		trunc = true
	}
	return draw()
end


local function camera_move(k)
	if k == "R" then
		camera.pos[3] = camera.pos[3] + 10
	elseif k == "F" then
		camera.pos[3] = camera.pos[3] - 10
	elseif k == "Z" then
		camera.focus = camera.focus * 0.8
	elseif k == "X" then
		camera.focus = camera.focus / 0.8
	else
		local x = 0
		local y = 0
		if k == "W" then
			x = 10 * math.cos(camera.yaw)
			y = 10 * math.sin(camera.yaw)
		elseif k == "S" then
			x = -10 * math.cos(camera.yaw)
			y = -10 * math.sin(camera.yaw)
		elseif k == "A" then
			x = 10 * math.cos(camera.yaw + math.pi/2)
			y = 10 * math.sin(camera.yaw + math.pi/2)
		elseif k == "D" then
			x = 10 * math.cos(camera.yaw - math.pi/2)
			y = 10 * math.sin(camera.yaw - math.pi/2)
		end
		camera.pos[1] = camera.pos[1] + x
		camera.pos[2] = camera.pos[2] + y
	end
end


local function message(k,t)
	if not t then return end
	
	if string.find("WASDRFZX",k) then
		camera_move(k)
	elseif k == "up" then
		camera.pitch = math.min(math.pi,camera.pitch + math.pi/180)
	elseif k == "down" then
		camera.pitch = math.max(0,camera.pitch - math.pi/180)
	elseif k == "left" then
		camera.yaw = camera.yaw + math.pi/180
	elseif k == "right" then
		camera.yaw = camera.yaw - math.pi/180
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