
local function D3D_transform(p,t)
	local r = {}
	local w = t[4] + t[8] + t[12] + t[16]
	r[1] = (p[1]*t[1] + p[2]*t[5] + p[3]*t[9] + t[13]) / w
	r[2] = (p[1]*t[2] + p[2]*t[6] + p[3]*t[10] + t[14]) / w
	r[3] = (p[1]*t[3] + p[2]*t[7] + p[3]*t[11] + t[15]) / w
	return r
end

local function round(p)
	return {math.floor(p[1]),math.floor(p[2]),math.floor(p[3])}
end

local pos = {0,0,0}
local pitch = 0
local yaw = 0
local focus = 1


local function rotate_z()
	local c = math.cos(-yaw)
	local s = math.sin(-yaw)
	return {
		c,s,0,0,
		-s,c,0,0,
		0,0,1,0,
		0,0,0,1
	}
end

local function rotate_x()
	local c = math.cos(-pitch)
	local s = math.sin(-pitch)
	return {
		1,0,0,0,
		0,c,s,0,
		0,-s,c,0,
		0,0,0,1
	}
end

local function move()
	return {
		1,0,0,0,
		0,1,0,0,
		0,0,1,0,
		-pos[1],-pos[2],-pos[3],1
	}
end

local function proj()
	return {
		1,0,0,0,
		0,1,0,0,
		0,0,0,1/focus,
		0,0,0,0
	}
end

local function point(p,c)
	p = D3D_transform(p,move())
	p = D3D_transform(p,rotate_z())
	p = D3D_transform(p,rotate_x())
	p = D3D_transform(p,proj())
	if c then
		gdi.pixel(round(p),{pen = c})
	end
	return p
end

local function line(a,b,c)
	local p = point(a)
	local q = point(b)

	if c then
		gdi.line(round(p),round(q),{pen = c})
	end
	return p,q
end



return {
	point = point,
	line = line,
	camera = function(c)
		if c.pos then pos = c.pos end
		if c.pitch then pitch = c.pitch end
		if c.yaw then yaw = c.yaw end
		if c.focus then focus = c.focus end
	end
}