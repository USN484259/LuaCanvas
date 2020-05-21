
local function round(p)
	return math.floor(p+0.5)
end


local canvas3D = {
	__index = canvas3D

}

function canvas3D:new()
	local c3d = {}
	setmetatable(c3d,canvas3D)
	self.__index = self
	
	c3d.z_rec = {}
	
	c3d.pos = {0,0,0}
	c3d.facing = nil
	c3d.pitch = 0
	c3d.yaw = 0
	c3d.focus = 0
	c3d.trunc = true
	return c3d
end

function canvas3D:camera(cam)
		local r = {
			pos = self.pos,
			pitch = self.pitch,
			yaw = self.yaw,
			focus = self.focus,
			trunc = self.trunc,
		}
		if cam.pos then self.pos = cam.pos end
		if cam.pitch then self.pitch = cam.pitch; self.facing = nil end
		if cam.yaw then self.yaw = cam.yaw; self.facing = nil end
		if cam.focus then self.focus = cam.focus end
		if nil ~= cam.trunc then self.trunc = cam.trunc end
		return r
end



local function D3D_transform(p,t)
	local r = {}
	local w = t[4] + t[8] + t[12] + t[16]
	r[1] = (p[1]*t[1] + p[2]*t[5] + p[3]*t[9] + t[13]) / w
	r[2] = (p[1]*t[2] + p[2]*t[6] + p[3]*t[10] + t[14]) / w
	r[3] = (p[1]*t[3] + p[2]*t[7] + p[3]*t[11] + t[15]) / w
	return r
end

local function rotate_z(yaw)
	local c = math.cos(-math.pi/2-yaw)
	local s = math.sin(-math.pi/2-yaw)
	return {
		c,s,0,0,
		-s,c,0,0,
		0,0,1,0,
		0,0,0,1
	}
end

local function rotate_x(pitch)
	local c = math.cos(math.pi + pitch)
	local s = math.sin(math.pi + pitch)
	
	return {
		1,0,0,0,
		0,c,s,0,
		0,-s,c,0,
		0,0,0,1
	}

end

local function move(pos)
	return {
		1,0,0,0,
		0,1,0,0,
		0,0,1,0,
		-pos[1],-pos[2],-pos[3],1
	}
end

function canvas3D:project(p)
	if self.trunc and p[3] < 0 then return end
	if self.focus <= 0 then return p end
	local factor = 1 + math.abs(p[3])/self.focus/256
	return {p[1]/factor,p[2]/factor,p[3],p[3]}
end

function canvas3D:translate(p)
	p = D3D_transform(p,move(self.pos))
	p = D3D_transform(p,rotate_z(self.yaw))
	p = D3D_transform(p,rotate_x(self.pitch))
	p[1] = -p[1]
	return p
end

function canvas3D:point(p,c)
		p = self:translate(p)
		p = self:project(p)
		if p and c then
			gdi.pixel(p,c)
		end
		return p
end

local function line_trunc(p,r)
	local dx = r[1] - p[1]
	local dy = r[2] - p[2]
	local dz = r[3] - p[3]
	
	local ratio = math.abs(p[3]) / dz
	
	return {p[1] + dx*ratio, p[2] + dy*ratio,0}

end

function canvas3D:draw_line(a,b,c)
	local p = self:project(a)
	local q = self:project(b)

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

function canvas3D:line(a,b,c)
	a = self:translate(a)
	b = self:translate(b)
	
	return self:draw_line(a,b,c)
end


local function normal_vector(a,b,c)
	local v1 = {b[1] - a[1],b[2] - a[2],b[3] - a[3]}
	local v2 = {c[1] - b[1],c[2] - b[2],c[3] - b[3]}

	return {
		v1[2]*v2[3] - v1[3]*v2[2],
		v1[3]*v2[1] - v1[1]*v2[3],
		v1[1]*v2[2] - v1[2]*v2[1]
	}
end


local function bound_step(b)
	local dy = math.floor(b.pt[2]) + 1 - b.pt[2]
	dy = math.min(b.ym - b.pt[2],dy)
	b.pt[1] = b.pt[1] + dy*b.dx
	b.pt[2] = b.pt[2] + dy
	b.pt[3] = b.pt[3] + dy*b.dz
	return b
end

function canvas3D:fill(pt,c)
	local bounds = {}
	
	for i = 1,#pt,1 do
		local a,b = pt[i],pt[i % #pt + 1]
		a = self:translate(a)
		b = self:translate(b)
		
		if a[2] > b[2] then a,b = b,a end
		
		--a,b = round(a),round(b)
		if b[2] ~= a[2] then
			bounds[#bounds+1] = {
				ym = b[2],
				pt = a,
				dx = (b[1]-a[1])/(b[2]-a[2]),
				dz = (b[3]-a[3])/(b[2]-a[2])
			}
		end
	end
	
	table.sort(bounds,function(a,b)
		if a.pt[2] == b.pt[2] then return a.pt[1] < b.pt[1] end
		return a.pt[2] < b.pt[2]
	end)
	
	while #bounds > 1 do
		local cur_y = round(bounds[1].pt[2])
		local i = 1
		while i < #bounds do
			local a,b = bounds[i],bounds[i+1]
			if cur_y < round(a.pt[2]) then break end
			
			self:draw_line(a.pt,b.pt,c)

			if a.pt[2] < a.ym then
				bounds[i] = bound_step(a)
			else
				table.remove(bounds,i)
				i = i - 1
			end
			if b.pt[2] < b.ym then
				bounds[i+1] = bound_step(b)
			else
				table.remove(bounds,i+1)
				i = i - 1
			end
			i = i + 2
		end
		table.sort(bounds,function(a,b)
			if a.pt[2] == b.pt[2] then return a.pt[1] < b.pt[1] end
			return a.pt[2] < b.pt[2]
		end)
	end
end


function canvas3D:surface(pt,c)
	if #pt < 3 then error("canvas3D::surface at least 3 points needed") end
	
	local brush,pen
	
	if type(c) == "table" and (c.pen or c.brush) then
		brush,pen = c.brush,c.pen
	else
		brush = c
	end
	
	local norm = normal_vector(pt[1],pt[2],pt[3])
	
	if not self.facing then
		local s = math.sin(self.pitch)
		self.facing = {s*math.cos(self.yaw),s*math.sin(self.yaw),-math.cos(self.pitch)}
	end
	
	if self.facing[1]*norm[1] + self.facing[2]*norm[2] + self.facing[3]*norm[3] >= 0 then return end
	
	if brush then
		self:fill(pt,brush)
	--error("TODO fill surface")
	end
	
	if pen then
	
		for i = 1,#pt,1 do
			local a,b = pt[i],pt[i % #pt + 1]
			self:line(a,b,pen)
		end
	
	end
end


return canvas3D