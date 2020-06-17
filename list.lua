local List = {
	__index = List,
	__len = function(self)
		return #self.content
	end
}

function List:new(p,a)
	local list = {}
	setmetatable(list,self)
	self.__index = self
	list.content = {}
	list.range = {}
	list.pos = p
	list.attr = a
	list.left,list.right = 0,0
	list.need_draw = true
	return list

end


function List:draw()
	local i = 1
	local y = self.pos[2] + 1
	local width = 0
	local axis_mask = 1
	if gdi.get("axis") == "world" then axis_mask = -1 end
	
	local bars = {self.pos[2]}
	self.range = {}
	
	while true do
		local entrance = self.content[i]
		if nil == entrance then break end
		local w,h = gdi.text({self.pos[1] + 1,y},entrance.str,entrance.attr or self.attr)
		local next_y = y + axis_mask*h
		self.range[i] = { math.min(y,next_y) , math.max(y,next_y) }
		width = math.max(width,w)
		bars[#bars + 1] = next_y
		y = next_y + axis_mask
		i = i + 1
	end
	
	self.left = self.pos[1] + 1
	self.right = self.left + width
	
	gdi.line({self.pos[1],self.pos[2]},{self.pos[1],y},self.attr)
	gdi.line({self.pos[1] + width + 1,self.pos[2]},{self.pos[1] + width + 1,y},self.attr)
	
	for _,l in pairs(bars) do
		gdi.line({self.left,l},{self.right,l},self.attr)
	
	end
	
	need_draw = false
end


function List:insert(str,pos)
	if pos == nil then pos = #self.content + 1 end
	if pos <= 0 or pos > #self.content + 1 then error("List:insert out of range") end
	if type(str) == "string" then
		table.insert(self.content,pos,{str = str})
	elseif type(str) == "table" then
		table.insert(self.content,pos,str)
	else
		error("List:insert expect string or table")
	end
	need_draw = true
	return pos
end

function List:erase(pos)
	if pos == nil then pos = #self.content end
	if pos <= 0 or pos > #self.content then error("List:erase out of range") end
	table.remove(self.content,pos)
	need_draw = true
	return pos
end

function List:find(p)
	if math.type(p) == "integer" then return self.content[p] end
	if type(p) == "string" then
		for i,entrance in pairs(self.content) do
			if entrance.str == p then
				return i
			end
		end
		return nil
	end
	
	if type(p) ~= "table" then error("List:find expect index string or point") end
	
	if need_redraw then return end
	
	if self.left < p[1] and p[1] < self.right then
	else
		return
	end
	
	for i,rect in pairs(self.range) do
		if rect[1] < p[2] and p[2] < rect[2] then
				return i
		end
	
	end

end




return List