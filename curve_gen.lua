local List = require('list')

local B_spline_curve = require('B_spline_curve')

local Curve = {
	__index = Curve
}

function Curve:new(p,s)
	local curve = {}
	setmetatable(curve,Curve)
	self.__index = self
	
	curve.list = List:new(p)
	
	for i = 1,4,1 do
		curve.list:insert({str = "0,0",node = {0,0}})
	end
	
	curve.str = s
	
	return curve
end


function Curve:draw(draw_list)
	if draw_list then self.list:draw() end

	local nodes = {}
	for i = 1,4,1 do
		nodes[i] = self.list:find(i).node
	end
	
	B_spline_curve.draw_nodes(nodes)
	B_spline_curve.draw_curve(nodes)

end


function Curve:node(p,i)
	if not i then i = self.focus end
	
	if not i then return end
	
	local entrance = self.list:find(i)
	local old = entrance.node
	
	if p then entrance.node = p end

	return old
end

function Curve:click(k,p)
	if k == 3 and self.focus then	--Rbutton
		self.list:find(self.focus).attr = nil
		self.focus = nil
		return true
	end
	if k == 1 then
	
		if self.focus then
			local entrance = self.list:find(self.focus)
			entrance.node = p
			entrance.str = ""..p[1]..','..p[2]
			return true
		end
	
		local index = self.list:find(p)
		if index then
			self.focus = index
			self.list:find(index).attr = {text = {0xFF,0,0}}
			return true
		end
	
	end

end

local curves
local focus

local function draw()
	gdi.fill()

	curves:draw()
	
	for i = 1,#curves,1 do
		curves:find(i):draw(i == focus)
	end

	return true
end



local function curve_click(k,p)
	if k == 3 and focus then
		curves:find(focus).attr = nil
		focus = nil
		return true
	end
	if k == 1 and not focus then
		focus = curves:find(p)
		if focus then
			curves:find(focus).attr = {text = {0xFF,0,0}}
			return true
		end
	
	end

end

local function keybd(key,press)
	if not press then return end
	local redraw = false
	if key == "delete" and focus then
		curves:erase(focus)
		focus = nil
		redraw = true
	end
	if key == "enter" then
		curves:insert(Curve:new({-390,0},"curve "..#curves))
		redraw = true
	end
	if redraw then return draw() end
end

local function init()
	curves = List:new({-390,290})
	focus = nil

end

local function click(k,p)
	local redraw = false
	if focus and curves:find(focus):click(k,p) then
		redraw = true
	else
		redraw = curve_click(k,p)
	end
	if redraw then return draw() end
end



local function entry(msg,argu)
	if msg == "draw" and not argu then
		init()
		return draw()
	end
	if msg == "mouse" then
		local x,y = gdi.cursor()
		return click(argu,{x,y})
	end
	return keybd(msg,argu)

end


return entry,{
	size = {800,600},
	axis = "world"

}