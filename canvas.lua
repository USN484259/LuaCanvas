




local function line_init(x1,y1,x2,y2)
	local this = {}

	this.x,this.y = x1,y1
	this.dx,this.dy = math.abs(x2-x1),math.abs(y2-y1)
	
	if x1 <= x2 then
		this.sx = 1
	else
		this.sx = -1
	end
	
	if y1 <= y2 then
		this.sy = 1
	else
		this.sy = -1
	end
	
	if this.dy < this.dx then
		this.interchange = false
	else
		this.dx,this.dy = this.dy,this.dx
		this.interchange = true
	end

	this.m = 2*this.dy

	this.f = this.m - this.dx

	return this
end


local function line_step(this,i)
	if i > this.dx then return false end
	gdi.pixel({this.x,this.y},0)
	
	if this.interchange then
		this.y = this.y + this.sy
	else
		this.x = this.x + this.sx
	end

	if this.f >= 0 then
		if this.interchange then
			this.x = this.x + this.sx
		else
			this.y = this.y + this.sy
		end
		this.f = this.f - 2*this.dx
		
	end
	
	this.f = this.f + this.m
	
	return true
end



local function circle_init(x,y,r)
	local this = {}
	
	this.x0,this.y0 = x,y
	this.r = r
	this.x,this.y = 0,r
	this.d = 1-r

	return this
end

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

local function circle_step(this,i)
	if this.x > this.y then return false end
	
	if i % 2 ~= 0 then return true end
	
	circle_points(this.x0,this.y0,this.x,this.y)
	
	if this.d < 0 then
		this.d = this.d + 2*this.x + 3
	else
		this.d = this.d + 2*(this.x-this.y) + 5
		this.y = this.y - 1
	end
	
	this.x = this.x + 1
	return true
end


local context_line
local context_circle


local function draw(index)
	if index == 0 then
		gdi.fill()
		local x1,x2 = math.random(-400,400),math.random(-400,400)
		local y1,y2 = math.random(-300,300),math.random(-300,300)
		
		gdi.text({-400,300},"line "..x1..','..y1..' '..x2..','..y2)
		
		context_line = line_init(x1,y1,x2,y2)
		
		local x0,y0 = math.random(-400,400),math.random(-300,300)
		local r = math.random(1,300)
		
		gdi.text({-400,250},"circle "..x0..','..y0..' '..r)
		
		context_circle = circle_init(x0,y0,r)
	end
	local cnt = 0
	if line_step(context_line,index) then cnt = cnt + 1 end
	if circle_step(context_circle,index) then cnt = cnt + 1 end
	if cnt > 0 then
		return index + 1
	end
	
end



return draw,{
	size = {800,600},
	brush = 0xFFFFFF,
	anime = 40,
	axis = "world",
}