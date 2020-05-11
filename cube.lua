local d3d = require('canvas3D')


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

--[[
local function round(p)
	return {
		math.floor(p[1]),
		math.floor(p[2])
	}


end

local axis_line = {
	{{0,0,0},{1000,0,0},{0xFF,0,0}},
	{{0,0,0},{0,1000,0},{0,0xFF,0}},
	{{0,0,0},{0,0,1000},{0,0,0xFF}}
}
--]]

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
	local c = d3d.camera({focus = 0,trunc = false})
	
	d3d.line(camera.pos,{camera.pos[1]+100,camera.pos[2],camera.pos[3]},{0xFF,0x60,0x60})
	--d3d.line(camera.pos,{camera.pos[1]-10000,camera.pos[2],camera.pos[3]},{0xFF,0,0})
	
	d3d.line(camera.pos,{camera.pos[1],camera.pos[2]+100,camera.pos[3]},{0x60,0xFF,0x60})
	--d3d.line(camera.pos,{camera.pos[1],camera.pos[2]-10000,camera.pos[3]},{0,0xFF,0})

	d3d.line(camera.pos,{camera.pos[1],camera.pos[2],camera.pos[3]+100},{0x60,0x60,0xFF})
	--d3d.line(camera.pos,{camera.pos[1],camera.pos[2],camera.pos[3]-10000},{0,0,0xFF})
	
	d3d.camera(c)
end



local function draw()

		
	gdi.fill()
	d3d.camera(camera)
	
	axis()
	
	local x,y
	
	for y = -2,2,1 do
		for x = -2,2,1 do
			cube({x*200,y*200,0})
		end
	end
	local str = "pos "..camera.pos[1]..' '..camera.pos[2]..' '..camera.pos[3]
	gdi.text({-400,300},str)
	str = "view "..camera.pitch..' '..camera.yaw..' '..camera.focus
	gdi.text({-400,280},str)

	d3d.line({-50,0,0},{-50,0,10000},0)
	d3d.line({50,0,0},{50,0,10000},0)
	
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
			x = 10 * math.cos(camera.yaw-math.pi/2)
			y = 10 * math.sin(camera.yaw-math.pi/2)
		elseif k == "S" then
			x = -10 * math.cos(camera.yaw-math.pi/2)
			y = -10 * math.sin(camera.yaw-math.pi/2)
		elseif k == "A" then
			x = -10 * math.cos(camera.yaw)
			y = -10 * math.sin(camera.yaw)
		elseif k == "D" then
			x = 10 * math.cos(camera.yaw)
			y = 10 * math.sin(camera.yaw)
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
		camera.pitch = math.min(math.pi/2,camera.pitch + math.pi/180)
	elseif k == "down" then
		camera.pitch = math.max(-math.pi/2,camera.pitch - math.pi/180)
	elseif k == "left" then
		camera.yaw = camera.yaw - math.pi/180
	elseif k == "right" then
		camera.yaw = camera.yaw + math.pi/180
	else
		return
	end

	return true
end


local function entry(arg1,arg2)
	if type(arg1) == "string" and message(arg1,arg2) then
		draw()
		return true
	end
	if type(arg1) == "number" and arg1 == 0 then
		camera = {
			pos = {0,0,0},
			pitch = 0,
			yaw = 0,
			focus = 1
		}
		draw()
		return 1
	end

end



return entry,{
	size = {800,600},
	brush = 0xFFFFFF,
	axis = "world",
	interactive = true
}