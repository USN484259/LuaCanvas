
local function D3D_transform(p,t)
	local r = {}
	local w = t[4] + t[8] + t[12] + t[16]
	r[1] = (p[1]*t[1] + p[2]*t[5] + p[3]*t[9] + t[13]) / w
	r[2] = (p[1]*t[2] + p[2]*t[6] + p[3]*t[10] + t[14]) / w
	r[3] = (p[1]*t[3] + p[2]*t[7] + p[3]*t[11] + t[15]) / w
	return r
end

local pos = {0,0,0}
local pitch = - math.pi / 2
local yaw = 0
local focus = 0


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
	local c = math.cos(math.pi/2 - pitch)
	local s = math.sin(math.pi/2 - pitch)
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


return {
	point = function(p)
		p = D3D_transform(p,move())
		p = D3D_transform(p,rotate_z())
		p = D3D_transform(p,rotate_x())
		return p
	end,
	camera = function(c)
		if c.pos then pos = c.pos end
		if c.pitch then pitch = c.pitch end
		if c.yaw then yaw = c.yaw end
		if c.focus then focus = c.focus end
	end
}