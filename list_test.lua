local List = require('list')



local list

local message

local function init()
	message = nil
	list = List:new({-400,300})
	for i = string.byte('A'),string.byte('Z'),1 do
		list:insert(string.char(i))
	end

end


local function redraw(index)
	
	gdi.fill()
	list:draw()
	
	if message then
		gdi.text({0,0},message)
	end
	
	
	return 1
end


local function click(k)
	if k < 0 then return end
	if k == 1 then 
		local x,y = gdi.cursor()
		local pos = {x,y}
		--message = (message or "")..x..' '..y
		local index = list:find(pos)
		if not index then return end
	
		message = (message or "")..list:find(index)
		
	elseif k == 3 then
		list:insert(message)
		message = nil
	end
	
	redraw()
	return true
end

local function entry(a,b)
	if type(a) == "number" then
		if a == 0 then init() end
		redraw()
		return 1
	end
	if a == "mouse" then return click(b) end

end

return entry,{
	size = {800,600},
	brush = 0xFFFFFF,
	axis = "world",
	interactive = true
}