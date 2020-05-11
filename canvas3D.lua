
local function D3D_transform(p,t)
	local r = {}
	local w = t[4] + t[8] + t[12] + t[16]
	r[1] = (p[1]*t[1] + p[2]*t[5] + p[3]*t[9] + t[13]) / w
	r[2] = (p[1]*t[2] + p[2]*t[6] + p[3]*t[10] + t[14]) / w
	r[3] = (p[1]*t[3] + p[2]*t[7] + p[3]*t[11] + t[15]) / w
	return r
end


local pos = {0,0,0}
local pitch = 0
local yaw = 0
local focus = 1
local trunc = true


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
	local c = math.cos(-math.pi/2 + pitch)
	local s = math.sin(-math.pi/2 + pitch)
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

local function project(p)
	if trunc and p[3] < 0 then return end
	if focus <= 0 then return {p[1],p[2]} end
	local factor = 1 + math.abs(p[3])/focus/256
	return {p[1]/factor,p[2]/factor}
end

local function translate(p)
	p = D3D_transform(p,move())
	p = D3D_transform(p,rotate_z())
	p = D3D_transform(p,rotate_x())
	return p
end

local function point(p,c)
		p = translate(p)
		p = project(p)
		if p and c then
			gdi.pixel(p,{pen = c})
		end
		return p
end

local function line_trunc(p,r)
	local dx = r[1] - p[1]
	local dy = r[2] - p[2]
	local dz = r[3] - p[3]
	
	local ratio = math.abs(p[3]) / dz
	
	return {p[1] + dx*ratio, p[2] + dy*ratio}

end

local function line(a,b,c)
	a = translate(a)
	b = translate(b)
	
	local p = project(a)
	local q = project(b)
	
	if p or q then
	else return end
	
	if not p then
		p = line_trunc(a,b)
	elseif not q then
		q = line_trunc(b,a)
	end
	

	if c then
		gdi.line(p,q,{pen = c})
	end
	return p,q
end



return {
translate = translate,
	point = point,
	line = line,
	camera = function(c)
		local r = {
			pos = pos,
			pitch = pitch,
			yaw = yaw,
			focus = focus,
			trunc = trunc
		}
		if c.pos then pos = c.pos end
		if c.pitch then pitch = c.pitch end
		if c.yaw then yaw = c.yaw end
		if c.focus then focus = c.focus end
		if nil ~= c.trunc then trunc = c.trunc end
		return r
	end
}