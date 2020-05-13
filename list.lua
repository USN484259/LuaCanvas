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
	list.area = {}
	list.pos = p
	list.attr = a
	return list

end


function List:draw()
	local i = 1
	local y = self.pos[2]
	local axis_mask = 1
	
	if gdi.axis() == "world" then axis_mask = -1 end
	
	while true do
		local str = self.content[i]
		if nil == str then break end
		local w,h = gdi.text({self.pos[1],y},str,self.attr)
		local next_y = y + axis_mask*h
		self.area[i] = { {self.pos[1],math.min(y,next_y)} , {self.pos[1] + w,math.max(y,next_y)} }
		y = next_y
		i = i + 1
	end
end


function List:insert(str,pos)
	if type(str) ~= "string" then error("List:insert expect string") end
	if pos == nil then pos = #self.content + 1 end
	if pos <= 0 or pos > #self.content + 1 then error("List:insert out of range") end
	table.insert(self.content,pos,str)
	self.area = {}
end

function List:erase(pos)
	if pos == nil then pos = #self.content end
	if pos <= 0 or pos > #self.content then error("List:erase out of range") end
	table.remove(self.content,pos)
	self.area = {}
end

function List:find(p)
	if math.type(p) == "integer" then return self.content[p] end
	
	for i,rect in pairs(self.area) do
		local a,b = rect[1],rect[2]
		if a[1] < p[1] and p[1] < b[1]
			and a[2] < p[2] and p[2] < b[2] then
				return i
		end
	
	end

end

return List