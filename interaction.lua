local str



local function draw(index)
	if index == 0 then str = "" end
	gdi.fill()
	gdi.text({0,0},index..' '..str)


	return index + 1
end


local function msg(k,s)
	if (type(k) == "number") then return draw(k) end
	
	str = str..k
	if s then str = str .. "+"
	else str = str .. "-"
	end
	
	str = str..' '



end





return msg,{
	size = {1000,400},
	brush = 0xFFFFFF,
	anime = 200,
	--axis = "world",
	interactive = true
}