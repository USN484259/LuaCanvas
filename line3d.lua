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

local function round(p)
	return {
		math.floor(p[1]),
		math.floor(p[2])
	}


end

local axis_line = {
	{{-1000,0,0},{1000,0,0},{0xFF,0,0}},
	{{0,-1000,0},{0,1000,0},{0,0xFF,0}},
	{{0,0,-1000},{0,0,1000},{0,0,0xFF}}
}

local function axis()
	for _,l in pairs(axis_line) do
		local a = d3d.point(l[1])
		local b = d3d.point(l[2])
		gdi.line(round(a),round(b),{pen = l[3]})
	end
end


local camera = {}


local function draw(index)

	if index == 0 then
		camera = {
			pos = {100,100,100},
			pitch = math.pi/2,
			yaw = 0

		}
	end

	gdi.fill()
	d3d.camera(camera)
	
	axis()
	
	for _,l in pairs(shape) do
		local a = d3d.point(l[1])
		local b = d3d.point(l[2])
		gdi.line(round(a),round(b))
	end
	
	
	camera.pitch = camera.pitch - math.pi/180
	camera.yaw = camera.yaw + math.pi/90
	
	
	if index < 180 then return index + 1 end
	
	

end

return draw,{
	size = {800,600},
	brush = 0xFFFFFF,
	anime = 40,
	axis = "world",
}