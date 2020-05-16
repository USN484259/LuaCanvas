local List = require('list')



local list

local message

local function init()
	message = nil
	list = List:new({-380,290},{text = 0xFF0000})
	for i = string.byte('A'),string.byte('Z'),1 do
		list:insert(string.char(i))
	end

end


local function redraw(timer)
		
	gdi.fill()
	list:draw()
	
	if message then
		gdi.text({0,0},message)
	end
	
end

local last_click

local function click(k)
	if k < 0 then return end
	if k == 1 then 
		local x,y = gdi.cursor()
		local pos = {x,y}
		--message = (message or "")..x..' '..y
		local index = list:find(pos)
		if not index then return end
		local obj = list:find(index)
		message = (message or "")..obj.str
		
		if last_click then
			list:find(last_click).attr = nil
		end
		
		last_click = index
		
		obj.attr = {text = {0xFF,0,0}}
		
	elseif k == 3 and message then
		list:insert(message)
		message = nil
	end
	
	redraw()
	return true
end

local function entry(a,b)
	if a == "draw" then
		if not b then
			init()
		end
		redraw()
		return true
	end
	if a == "mouse" then return click(b) end

end

return entry,{
	size = {800,600},
	brush = 0xFFFFFF,
	axis = "world",
	interactive = true
}