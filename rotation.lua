
local function circle_points(x0,y0,x,y)
	gdi.pixel({x0+x,y0+y},0)
	gdi.pixel({x0+x,y0-y},0)
	gdi.pixel({x0-x,y0+y},0)
	gdi.pixel({x0-x,y0-y},0)
	gdi.pixel({x0+y,y0+x},0)
	gdi.pixel({x0-y,y0+x},0)
	gdi.pixel({x0+y,y0-x},0)
	gdi.pixel({x0-y,y0-x},0)
end

local function draw_circle(x0,y0,r)
	local x,y = 0,r
	local d = 1-r

	while x <= y do
		circle_points(x0,y0,x,y)
		if d < 0 then
			d = d + 2*x + 3
		else
			d = d + 2*(x-y) + 5
			y = y - 1
		end
		
		x = x + 1
	end



end


local function D2D_transform(p,t)
	local r = {}
	local w = t[3]+t[6]+t[9]
	r.x = (p.x*t[1] + p.y*t[4] + t[7]) / w
	r.y = (p.x * t[2] + p.y * t[5] + t[8]) /w
	return r
end

local function round_point(p)
	return {math.floor(p.x),math.floor(p.y)}

end

local base = {
	{x=-40,y=-40},
	{x=-40,y=40},
	{x=40,y=40},
	{x=40,y=-40}
}



local function expand(index)
		
	local ang_cos = math.cos(index * math.pi / 24)
	local ang_sin = math.sin(index * math.pi / 24)

	
	local rotate = {
		ang_cos,	ang_sin,		0,
		-ang_sin,		ang_cos,	0,
		0,		0,		1
	}
	local scale = {
		1 + 0.2*index,	0,		0,
		0,		1+0.2*index,	0,
		0,			0,			1
	
	}
	
	local points = {}
	local i
	for i = 1,4,1 do
		points[i] = D2D_transform(base[i],rotate)
		points[i] = D2D_transform(points[i],scale)
		points[i] = round_point(points[i])
	end
	
	for i=1,4,1 do
		gdi.line(points[i],points[i%4 + 1])

	end
	

end


local function wheel(index)
	local ang_cos = math.cos(index * math.pi / 12)
	local ang_sin = math.sin(index * math.pi / 12)

	local matrix = {
		ang_cos,	ang_sin,		0,
		-ang_sin,		ang_cos,	0,
		600 - 60 * index*math.pi/12,		0,		1
	}
	local points = {}
	local i
	for i = 1,4,1 do
		points[i] = D2D_transform(base[i],matrix)
		points[i] = round_point(points[i])
	end
	
	for i=1,4,1 do
		gdi.line(points[i],points[i%4 + 1])

	end
	gdi.line({-600,-60},{600,-60})
	draw_circle(math.floor(600 - 60 * index*math.pi/12),0,60)


end



local function draw(index)
	gdi.fill()
	if index < 80 then
		expand(index)
	else
		wheel(index - 80)
	end

	if index < 160 then return index + 1 end

end

return draw,{
	size = {1024,768},
	brush = 0xFFFFFF,
	anime = 40,
	axis = "world",
}