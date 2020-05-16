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


return {
	draw_nodes = draw_nodes,
	draw_curve = curve



}