-- Vector3 class
 
local vector3 = {__type = "vector3"};
local mt = {__index = vector3};
 
-- built-in functions
 
local sqrt = math.sqrt;
local acos = math.acos;
local cos = math.cos;
local sin = math.sin;
 
-- private functions
 
local function calcMagnitude(v)
	return sqrt(v.x^2 + v.y^2 + v.z^2);
end;
 
local function normalize(v)
	local magnitude = sqrt(v.x^2 + v.y^2 + v.z^2);
	if magnitude > 0 then
		return vector3.new(v.x / magnitude, v.y / magnitude, v.z / magnitude);
	else
		-- avoid 'nan' case
		return vector3.new(0, 0, 0);
	end;
end;
 
-- meta-methods
 
function mt.__index(v, index)
	if (index == "unit") then
		return normalize(v);
	elseif (index == "magnitude") then
		return calcMagnitude(v);
	elseif vector3[index] then
		return vector3[index];
	elseif rawget(v, "proxy")[index] then
		return rawget(v, "proxy")[index];
	else
		error(index .. " is not a valid member of Vector3");
	end;
end;
 
function mt.__newindex(v, index, value)
	error(index .. " cannot be assigned to");
end;
 
function mt.__add(a, b)
	local aIsVector = type(a) == "table" and a.__type and a.__type == "vector3";
	local bIsVector = type(b) == "table" and b.__type and b.__type == "vector3";
	if (aIsVector and bIsVector) then
		return vector3.new(a.x + b.x, a.y + b.y, a.z + b.z);
	elseif (bIsVector) then
		-- check for custom type
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (Vector3 expected, got " .. cust .. ")");
	elseif (aIsVector) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (Vector3 expected, got " .. cust .. ")");
	end;
end;
 
function mt.__sub(a, b)
	local aIsVector = type(a) == "table" and a.__type and a.__type == "vector3";
	local bIsVector = type(b) == "table" and b.__type and b.__type == "vector3";
	if (aIsVector and bIsVector) then
		return vector3.new(a.x - b.x, a.y - b.y, a.z - b.z);
	elseif (bIsVector) then
		-- check for custom type
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (Vector3 expected, got " .. cust .. ")");
	elseif (aIsVector) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (Vector3 expected, got " .. cust .. ")");
	end;
end;
 
function mt.__mul(a, b)
	if (type(a) == "number") then
		return vector3.new(a * b.x, a * b.y, a * b.z);
	elseif (type(b) == "number") then
		return vector3.new(a.x * b, a.y * b, a.z * b);
	elseif (a.__type and a.__type == "vector3" and  b.__type and b.__type == "vector3") then
		return vector3.new(a.x * b.x, a.y * b.y, a.z * b.z);
	else
		error("attempt to multiply a Vector3 with an incompatible value type or nil");
	end;
end;
 
function mt.__div(a, b)
	if (type(a) == "number") then
		return vector3.new(a / b.x, a / b.y, a / b.z);
	elseif (type(b) == "number") then
		return vector3.new(a.x / b, a.y / b, a.z / b);
	elseif (a.__type and a.__type == "vector3" and  b.__type and b.__type == "vector3") then
		return vector3.new(a.x / b.x, a.y / b.y, a.z / b.z);
	else
		error("attempt to divide a Vector3 with an incompatible value type or nil");
	end;
end;
 
function mt.__unm(v)
	return vector3.new(-v.x, -v.y, -v.z);
end;
 
function mt.__tostring(v)
	return v.x .. ", " .. v.y .. ", " .. v.z;
end;
 
mt.__metatable = false;
 
-- public class
 
function vector3.new(x, y, z)
	local self = {};
	self.proxy = {};
	self.proxy.x = x or 0;
	self.proxy.y = y or 0;
	self.proxy.z = z or 0;
	return setmetatable(self, mt);
end;
 
function vector3.FromNormalId(id)
	pcall(function() id = id.Value or id end);
	if (id == 0) then -- right
		return vector3.new(1, 0, 0);
	elseif (id == 1) then -- top
		return vector3.new(0, 1, 0);
	elseif (id == 2) then -- back
		return vector3.new(0, 0, 1);
	elseif (id == 3) then -- left
		return vector3.new(-1, 0, 0);
	elseif (id == 4) then
		return vector3.new(0, -1, 0);
	elseif (id == 5) then
		return vector3.new(0, 0, -1);
	end;
end;
 
function vector3.FromAxis(id)
	pcall(function() id = id.Value or id end);
	if (id == 0) then -- right
		return vector3.new(1, 0, 0);
	elseif (id == 1) then -- top
		return vector3.new(0, 1, 0);
	elseif (id == 2) then -- back
		return vector3.new(0, 0, 1);
	end;
end;
 
function vector3:Lerp(v3, t)
	return self + (v3 - self) * t;
end;
 
function vector3:Dot(v3)
	local isVector = v3.__type and v3.__type == "vector3";
	if (isVector) then
		return self.x * v3.x + self.y * v3.y + self.z * v3.z;
	else
		error("bad argument #1 to 'Dot' (Vector3 expected, got number)");
	end;
end;
 
function vector3:Cross(v3)
	local isVector = v3.__type and v3.__type == "vector3";
	if (isVector) then
		return vector3.new(
			self.y * v3.z - self.z * v3.y,
			self.z * v3.x - self.x * v3.z,
			self.x * v3.y - self.y * v3.x
		);
	else
		error("bad argument #1 to 'Cross' (Vector3 expected, got number)");
	end;
end;
 
return vector3;