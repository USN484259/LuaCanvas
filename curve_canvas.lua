local List = require('list')

local pos_coordinate = {-20,290}
local pos_toolbar = {-390,290}
local pos_curvelist = {330,290}
local pos_nodelist = {-390,-200}
local pos_msg = {-390,-280}


local function draw_grid(grain,color)
	if not grain then return end
	if not color then color = {0xCC,0xCC,0xCC} end
	local width,height = gdi.get("size")
	color = gdi.pen(color)
	
	gdi.line({-width/2,0},{width/2,0})
	gdi.line({0,-height/2},{0,height/2})
	
	if grain ~= 0 then
		local i = grain
		
		while i < math.max(width,height)/2 do
			gdi.line({-width/2,-i},{width/2,-i})
			gdi.line({-i,-height/2},{-i,height/2})
			
			gdi.line({-width/2,i},{width/2,i})
			gdi.line({i,-height/2},{i,height/2})
			
			i = i + grain
		end
	end
	
	gdi.pen(color)

end

local function draw_nodes(points,sel)
	local prev
	for i = 1,#points,1 do
		local p = points[i]
		if prev then
			gdi.line(prev,p,{pen = {0,0,0xFF}})
		end
		
		local color = 0
		local size = 2
		if i == sel then
			color = {0,0xCC,0xCC}
			size = 4
		end
		gdi.rectangle({p[1]-size,p[2]-size},{p[1]+size,p[2]+size},{pen = color,brush = color})

		prev = p
	end
end


local function curve_fun2(t,k)
	if k == 0 then
		return (t^2 - 2*t + 1)/2
	elseif k == 1 then
		return (-2*t^2 + 2*t + 1)/2
	elseif k == 2 then
		return t^2 /2
	end
end

local function curve_fun3(t,k)
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
local function draw_curve(points,color,dt)
	if dt == nil then dt = 0.001 end
	
	if color then
		color = gdi.pen(color)
	end
	local fun
	if #points == 3 then fun = curve_fun2 end
	if #points == 4 then fun = curve_fun3 end
	
	local t
	local prev
	for t=0,1,dt do
		local p = {0,0}
		local i
		for i=1,#points,1 do
			f = fun(t,i-1)
			p[1] = p[1] + points[i][1]*f
			p[2] = p[2] + points[i][2]*f
		end
		
		if prev then
			gdi.line(prev,p)
		end
		prev = p	
	end
	
	if color then
		gdi.pen(color)
	end
	
end


local node_list = {
	__index = node_list
}

function node_list:new(node_count,pos,str)
	local this = {}
	setmetatable(this,node_list)
	self.__index = self
	
	this.list = List:new(pos)
	
	for i = 1,node_count,1 do
		this.list:insert({str = "0,0",node = {0,0}})
	end
	this.focus = nil

	this.str = str

	return this
end

function node_list:draw(selected)
	local color = 0
	if selected then
		self.list:draw()
		color = {0xFF,0,0}
	end
	
	local nodes = {}
	for i = 1,#self.list,1 do
		nodes[i] = self.list:find(i).node
	end

	draw_curve(nodes,color)
	
	if selected then
		draw_nodes(nodes,self.focus)
	end
end

function node_list:selected()
	if self.focus then
		return self.list:find(self.focus)
	end
end

function node_list:node(index,pos)	
	local old = self.list:find(index).node
	
	if pos then
		local obj = self.list:find(index)
		obj.node = pos
		obj.str = ""..pos[1]..","..pos[2]
	end
	
	return old
end


function node_list:message(msg,arg,pos)	--If handled return true
	if self.focus then	--already selected
		if msg == "mouse" and arg == 3 then		--RButton deselect
			self.list:find(self.focus).attr = nil
			self.focus = nil
			return true
		end
		
		
		if msg == "mouse" and arg == 1 then		--LButton, move node
			;
		elseif type(arg) == "boolean" and arg then	--keypress
			pos = self.list:find(self.focus).node
			if msg == "up" then
				pos[2] = pos[2] + 1
			elseif msg == "down" then
				pos[2] = pos[2] - 1
			elseif msg == "left" then
				pos[1] = pos[1] - 1
			elseif msg == "right" then
				pos[1] = pos[1] + 1
			else
				return	--other keys
			end
		else
			return
		end
		
		local obj = self.list:find(self.focus)
		obj.node = pos
		obj.str = ""..pos[1]..","..pos[2]
		
		return true
		
	elseif msg == "mouse" and arg == 1 then	--not selected, possibly select a node
		local index = self.list:find(pos)
		if index then
			self.focus = index
			self.list:find(index).attr = {font = {0xFF,0,0}}
			return true
		end
	end
end


local curve_list = {
	__index = curve_list
}

function curve_list:new(pos)
	local this = {}
	setmetatable(this,curve_list)
	self.__index = self
	
	this.list = List:new(pos)
	
	this.focus = nil
	
	return this
end

function curve_list:draw()
	self.list:draw()
	
	for i = 1,#self.list,1 do
		self.list:find(i):draw(i == self.focus)
	end

end

function curve_list:insert(node_count,name)
	if not name then
		if not self.nameindex then
			self.nameindex = 1
		end
		name = "Curve "..self.nameindex
		self.nameindex = self.nameindex + 1
	end
	
	local index = self.list:insert(node_list:new(node_count,pos_nodelist,name))
	local ret = self.list:find(index)
	ret.attr = {font = {0xFF,0,0}}
	if self.focus then
		self.list:find(self.focus).attr = nil
	end
	self.focus = index
	return ret
end

function curve_list:erase()
	if not self.focus then return end
	
	self.list:erase(self.focus)
	self.focus = nil
	return true

end

function curve_list:selected()
	if self.focus then
		return self.list:find(self.focus)
	end
end

function curve_list:message(msg,arg,pos)
	if self.focus then	--already selected
		if self.list:find(self.focus):message(msg,arg,pos) then
			return true
		end
		if msg == "mouse" and arg == 3 then	--RButton deselect
			self.list:find(self.focus).attr = nil
			self.focus = nil
			return true
		end
	end
	
	
	if msg == "mouse" and arg == 1 then	--not selected, possibly select a node
		local index = self.list:find(pos)
		if index then
			self.list:find(index).attr = {font = {0xFF,0,0}}
			if self.focus then
				self.list:find(self.focus).attr = nil
			end
			self.focus = index
			return true
		end
	end	
end


local toolbar = {
	__index = toolbar
}

function toolbar:new()
	local this = {}
	setmetatable(this,toolbar)
	self.__index = self
	
	this.list = List:new(pos_toolbar)
	this.curves = curve_list:new(pos_curvelist)
	
	this.list:insert("degree = 3")
	this.list:insert("continuous")
	this.list:insert("guides: axis")
	this.list:insert("new")
	this.list:insert("delete")
	
	this.node_set = nil
	this.node_count = 4
	this.guides = 0
	
	return this
end

function toolbar:draw()
	draw_grid(self.guides)
	self.list:draw()
	self.curves:draw()
	if self.node_set then
		draw_nodes(self.node_set)
	end
end

function toolbar:message(msg,arg,pos)
	if not self.node_set then
		if self.curves:message(msg,arg,pos) then
			return true
		elseif msg == "mouse" and arg == 1 then
			local index = self.list:find(pos)
			if index == 1 then
				if self.node_count == 4 then
					self.node_count = 3
				elseif self.node_count == 3 then
					self.node_count = 4
				end
				self.list:find(1).str = "degree = "..self.node_count-1
				return true
			elseif index == 2 then
				self.list:find(2).attr = {font = {0xFF,0,0}}
				self.node_set = {}
				return true
			elseif index == 3 then
				local obj = self.list:find(3)
				if self.guides == nil then
					self.guides = 0
					obj.str = "guides: axis"
				elseif self.guides == 0 then
					self.guides = 100
					obj.str = "guides: grid"
				else
					self.guides = nil
					obj.str = "guides: none"
				end
				return true
			elseif index == 4 then
				self.curves:insert(self.node_count)
				return true
			elseif index == 5 then
				return self.curves:erase()
			end
		end
		
	elseif msg == "mouse" then
		if arg == 3 then
			self.list:find(2).attr = nil
			self.node_set = nil
			return true
		end
		
		if arg == 1 then
			table.insert(self.node_set,pos)
			
			if #self.node_set == self.node_count then
				local curve = self.curves:insert(self.node_count)
				for i = 1,self.node_count,1 do
					curve:node(i,self.node_set[i])
					if i > 1 then
						self.node_set[i-1] = self.node_set[i]
					end
				end
				table.remove(self.node_set)
				
			
			end
			
			return true
		end
	
	end


end


local gui = nil

local help_toolbar = "点击degree切换次数 guides切换参考线 new新建曲线 在曲线列表中选择以查看或编辑曲线 continuous进入连续模式"
local help_continuous = "连续模式：左键放置下一个控制点，右键退出"
local help_nodelist = "左下列表中选择控制点进行调整，或者使用delete删除曲线"
local help_movenode = "调整控制点：方向键移动控制点，左键移动到该位置，右键退出"

local function get_help()
	if gui.node_set then
		return help_continuous
	end
	local curve = gui.curves:selected()
	if not curve then return help_toolbar end
	local node = curve:selected()
	if not node then return help_nodelist end
	return help_movenode

end


local function draw(coord)
	gdi.fill()
	gui:draw()
	if coord then
		gdi.text(pos_coordinate,'('..coord[1]..','..coord[2]..')')
	end
	gdi.text(pos_msg,get_help())
	return true
end


local function entry(msg,argu)
	if msg == "clear" then
		gui = nil
		collectgarbage()
		return true
	end
	if msg == "draw" then
		gui = toolbar:new()
		help_text = help_toolbar
		return draw()
	end
	
	if gui then
		local pos = table.pack(gdi.cursor())
		
		if gui:message(msg,argu,pos) or msg == "cursor" then
			return draw(pos)
		end

	end

end


return entry,{
	size = {800,600},
	axis = "world",
	pen = 0,
	font = 0
}