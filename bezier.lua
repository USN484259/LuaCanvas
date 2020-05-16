--local List = require('list')

local function draw_nodes(points)
	local prev
	for i = 1,4,1 do
		local p = points[i]
		gdi.rectangle({p[1]-2,p[2]-2},{p[1]+2,p[2]+2},{brush = 0})
		if prev then
			gdi.line(prev,p)
		end
		prev = p
	end
end

local function bernstein(t)
	return { (1-t)^3,3*t*(1-t)^2,3*t^2*(1-t),t^3 }
end



local function bezier(points,dt)
	if dt == nil then dt = 0.001 end
	local t
	for t = 0,1,dt do
		local p = {0,0}
		local b = bernstein(t)
		local i
		for i = 1,4,1 do
			p[1] = p[1] + points[i][1]*b[i]
			p[2] = p[2] + points[i][2]*b[i]
		end
		
		gdi.pixel(p,0)
		
	end

end


local function curve_fun(t,k)
	if k == 0 then
		return (-t^3+3*t^2-3*t+1)/6
	elseif k == 1 then
		return (3*t^3-6*t^2+4)/6
	elseif k == 2 then
		return (-3*t^3+3*t^2+3*t+1)/6
	elseif k == 3 then
		return t^3/6
	end

end


--B spline curve
local function curve(points,dt)
	if dt == nil then dt = 0.001 end
	local t

	for t=0,1,dt do
		local p = {0,0}
		local i
		for i=1,4,1 do
			f = curve_fun(t,i-1)
			p[1] = p[1] + points[i][1]*f
			p[2] = p[2] + points[i][2]*f
		end

		gdi.pixel(p,0)
		
	end
end

local function pt(x,y)
	return {x-300,y-200}
end


local bezier_lines = {
	{pt(57,82),pt(64,201),pt(206,282),pt(280,156)},
	{pt(101,160),pt(106,180),pt(132,197),pt(149,195)},
	{pt(280,156),pt(345,159),pt(385,134),pt(397,82)},
	{pt(84,94),pt(104,147),pt(164,147),pt(184,94)},
	{pt(274,94),pt(294,147),pt(354,147),pt(374,94)}
}

local lines = {
	{pt(57,82),pt(397,82)},
	{pt(149,195),pt(149,160)},
	{pt(101,160),pt(149,160)},
	{pt(240,160),pt(278,160)},
	{pt(240,160),pt(240,195)},
	{pt(240,195),pt(250,195)},
	{pt(170,195),pt(230,195)},
	{pt(170,160),pt(230,160)},
	{pt(170,195),pt(170,160)},
	{pt(230,195),pt(230,160)},
	{pt(160,216),pt(160,142)},
	{pt(160,142),pt(194,120)},
	{pt(194,120),pt(194,82)}


}

local function draw_car()

	for _,l in pairs(bezier_lines) do
		draw_nodes(l)
		bezier(l)
	end
	
	for _,l in pairs(lines) do
		gdi.line(l[1],l[2])
	end
	
	gdi.rectangle(pt(170,150),pt(200,140))
	gdi.ellipse(pt(94,120),pt(174,40))
	gdi.ellipse(pt(284,120),pt(364,40))

end

local points

local function draw_curve()
	if not points then points = {
		{-400,300},
		{400,-300},
		{-400,-300},
		{400,300}
	} end
	
	draw_nodes(points)

	curve(points)
	
	local diff = {
		{2,-3},
		{-4,1},
		{4,1},
		{-2,-3}
	}
	
	
	for i = 1,4,1 do
		points[i][1] = points[i][1] + diff[i][1]
		points[i][2] = points[i][2] + diff[i][2]
	end
	
end


local function draw(msg,timer)
	if msg ~= "draw" then return end
	
	
	if not timer then
		points = nil
		gdi.timer(40)
	end
	
	gdi.fill()
	draw_car()
	
	draw_curve()
	
	
	return true
end



return draw,{
	size = {800,600},
	axis = "world",
	brush = 0xFFFFFF
}