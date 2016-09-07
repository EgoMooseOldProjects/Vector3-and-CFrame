-- dependancies
 
local Vector3 = require("vector3");
 
-- CFrame class
 
local cframe = {__type = "cframe"};
local mt = {__index = cframe};
 
local prettyPrint = false; -- mainly for debug (not a feature in real CFrames)
 
-- built-in functions
 
local pi = math.pi;
local max = math.max;
local cos = math.cos;
local sin = math.sin;
local acos = math.acos;
local asin = math.asin;
local sqrt = math.sqrt;
local atan2 = math.atan2;
local unpack = unpack;
local concat = table.concat;
 
-- some variables
 
local identityMatrix = {
	m11 = 1, m12 = 0, m13 = 0,
	m21 = 0, m22 = 1, m23 = 0,
	m31 = 0, m32 = 0, m33 = 1
};
local m41, m42, m43, m44 = 0, 0, 0, 1;
local identityCFrame = {0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1};
 
local right = Vector3.new(1, 0, 0);
local top   = Vector3.new(0, 1, 0);
local back  = Vector3.new(0, 0, 1);
 
-- private functions
 
local function fromAxisAngle(axis, vector, theta)
	-- http://wiki.roblox.com/index.php?title=User:EgoMoose/Articles/Quaternions_and_slerping#Rodriguez_Rotation_formula:_Axis-angle_rotations
	local axis = axis.unit;
	return vector * cos(theta) + vector:Dot(axis) * axis * (1 - cos(theta)) + axis:Cross(vector) * sin(theta);
end;
 
local function cfTimesv3(cf, v3)
	local _, _, _, m11, m12, m13, m21, m22, m23, m31, m32, m33 = cf:components();
	local right = Vector3.new(m11, m21, m31);
	local top   = Vector3.new(m12, m22, m32);
	local back  = Vector3.new(m13, m23, m33);
	return cf.p + v3.x * right + v3.y * top + v3.z * back;
end;
 
local function fourByfour(a, b)
	local a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 = unpack(a);
	local b11, b12, b13, b14, b21, b22, b23, b24, b31, b32, b33, b34, b41, b42, b43, b44 = unpack(b);
	-- 4x4 matrix multiplication
	local m11 = a11*b11 + a12*b21 + a13*b31 + a14*b41;
	local m12 = a11*b12 + a12*b22 + a13*b32 + a14*b42;
	local m13 = a11*b13 + a12*b23 + a13*b33 + a14*b43;
	local m14 = a11*b14 + a12*b24 + a13*b34 + a14*b44;
	local m21 = a21*b11 + a22*b21 + a23*b31 + a24*b41;
	local m22 = a21*b12 + a22*b22 + a23*b32 + a24*b42;
	local m23 = a21*b13 + a22*b23 + a23*b33 + a24*b43;
	local m24 = a21*b14 + a22*b24 + a23*b34 + a24*b44;
	local m31 = a31*b11 + a32*b21 + a33*b31 + a34*b41;
	local m32 = a31*b12 + a32*b22 + a33*b32 + a34*b42;
	local m33 = a31*b13 + a32*b23 + a33*b33 + a34*b43;
	local m34 = a31*b14 + a32*b24 + a33*b34 + a34*b44;
	local m41 = a41*b11 + a42*b21 + a43*b31 + a44*b41;
	local m42 = a41*b12 + a42*b22 + a43*b32 + a44*b42;
	local m43 = a41*b13 + a42*b23 + a43*b33 + a44*b43;
	local m44 = a41*b14 + a42*b24 + a43*b34 + a44*b44;
	-- return the components
	return m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44;
end;
 
local function cfTimescf(cf1, cf2)
	local a14, a24, a34, a11, a12, a13, a21, a22, a23, a31, a32, a33 = cf1:components();
	local b14, b24, b34, b11, b12, b13, b21, b22, b23, b31, b32, b33 = cf2:components();
	local m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 = fourByfour({
		a11, a12, a13, a14,
		a21, a22, a23, a24,
		a31, a32, a33, a34,
		m41, m42, m43, m44
	}, {
		b11, b12, b13, b14,
		b21, b22, b23, b24,
		b31, b32, b33, b34,
		m41, m42, m43, m44
	});
	-- return the final CFrame
	return cframe.new(m14, m24, m34, m11, m12, m13, m21, m22, m23, m31, m32, m33);
end;
 
local function getDeterminant(cf)
	local a14, a24, a34, a11, a12, a13, a21, a22, a23, a31, a32, a33 = cf:components();
	local m41, m42, m43, m44 = 0, 0, 0, 1;
	local det =   a11*a22*a33*m44 + a11*a23*a34*m42 + a11*a24*a32*m43
				+ a12*a21*a34*m43 + a12*a23*a31*m44 + a12*a24*a33*m41
				+ a13*a21*a32*m44 + a13*a22*a34*m41 + a13*a24*a31*m42
				+ a14*a21*a33*m42 + a14*a22*a31*m43 + a14*a23*a32*m41
				- a11*a22*a34*m43 - a11*a23*a32*m44 - a11*a24*a33*m42
				- a12*a21*a33*m44 - a12*a23*a34*m41 - a12*a24*a31*m43
				- a13*a21*a34*m42 - a13*a22*a31*m44 - a13*a24*a32*m41
				- a14*a21*a32*m43 - a14*a22*a33*m41 - a14*a23*a31*m42;
	return det;
end;
 
local function invert4x4(cf)
	-- this is linear algebra. We're inverting a 4x4 matrix
	-- see: http://www.cg.info.hiroshima-cu.ac.jp/~miyazaki/knowledge/teche23.html
	-- it is very possible that the built-in CFrame class does not use this method as computers tend to use elimination methods
	-- regardless, both functions should return the same answer
	local a14, a24, a34, a11, a12, a13, a21, a22, a23, a31, a32, a33 = cf:components();
	local det = getDeterminant(cf);
	if (det == 0) then return cf; end;
	local b11 = (a22*a33*m44 + a23*a34*m42 + a24*a32*m43 - a22*a34*m43 - a23*a32*m44 - a24*a33*m42) / det;
	local b12 = (a12*a34*m43 + a13*a32*m44 + a14*a33*m42 - a12*a33*m44 - a13*a34*m42 - a14*a32*m43) / det;
	local b13 = (a12*a23*m44 + a13*a24*m42 + a14*a22*m43 - a12*a24*m43 - a13*a22*m44 - a14*a23*m42) / det;
	local b14 = (a12*a24*a33 + a13*a22*a34 + a14*a23*a32 - a12*a23*a34 - a13*a24*a32 - a14*a22*a33) / det;
	local b21 = (a21*a34*m43 + a23*a31*m44 + a24*a33*m41 - a21*a33*m44 - a23*a34*m41 - a24*a31*m43) / det;
	local b22 = (a11*a33*m44 + a13*a34*m41 + a14*a31*m43 - a11*a34*m43 - a13*a31*m44 - a14*a33*m41) / det;
	local b23 = (a11*a24*m43 + a13*a21*m44 + a14*a23*m41 - a11*a23*m44 - a13*a24*m41 - a14*a21*m43) / det;
	local b24 = (a11*a23*a34 + a13*a24*a31 + a14*a21*a33 - a11*a24*a33 - a13*a21*a34 - a14*a23*a31) / det;
	local b31 = (a21*a32*m44 + a22*a34*m41 + a24*a31*m42 - a21*a34*m42 - a22*a31*m44 - a24*a32*m41) / det;
	local b32 = (a11*a34*m42 + a12*a31*m44 + a14*a32*m41 - a11*a32*m44 - a12*a34*m41 - a14*a31*m42) / det;
	local b33 = (a11*a22*m44 + a12*a24*m41 + a14*a21*m42 - a11*a24*m42 - a12*a21*m44 - a14*a22*m41) / det;
	local b34 = (a11*a24*a32 + a12*a21*a34 + a14*a22*a31 - a11*a22*a34 - a12*a24*a31 - a14*a21*a32) / det;
	local b41 = (a21*a33*m42 + a22*a31*m43 + a23*a32*m41 - a21*a32*m43 - a22*a33*m41 - a23*a31*m42) / det;
	local b42 = (a11*a32*m43 + a12*a33*m41 + a13*a31*m42 - a11*a33*m42 - a12*a31*m43 - a13*a32*m41) / det;
	local b43 = (a11*a23*m42 + a12*a21*m43 + a13*a22*m41 - a11*a22*m43 - a12*a23*m41 - a13*a21*m42) / det;
	local b44 = (a11*a22*a33 + a12*a23*a31 + a13*a21*a32 - a11*a23*a32 - a12*a21*a33 - a13*a22*a31) / det;
	return cframe.new(b14, b24, b34, b11, b12, b13, b21, b22, b23, b31, b32, b33);
end;
 
local function quaternionToMatrix(i, j, k, w)
	local m11 = 1 - 2*j^2 - 2*k^2;
	local m12 = 2*(i*j - k*w);
	local m13 = 2*(i*k + j*w);
	local m21 = 2*(i*j + k*w);
	local m22 = 1 - 2*i^2 - 2*k^2;
	local m23 = 2*(j*k - i*w);
	local m31 = 2*(i*k - j*w);
	local m32 = 2*(j*k + i*w);
	local m33 = 1 - 2*i^2 - 2*j^2;
	return {0, 0, 0, m11, m12, m13, m21, m22, m23, m31, m32, m33};
end;
 
local function quaternionFromCFrame(cf)
	-- taken from: http://wiki.roblox.com/index.php?title=Quaternions_for_rotation#Quaternion_from_a_Rotation_Matrix
	local mx, my, mz, m11, m12, m13, m21, m22, m23, m31, m32, m33 = cf:components();
	local trace = m11 + m22 + m33;
	if (trace > 0) then
		local s = sqrt(1 + trace);
		local r = 0.5 / s;
		return s * 0.5, Vector3.new((m32 - m23) * r, (m13 - m31) * r, (m21 - m12) * r);
	else -- find the largest diagonal element
		local big = max(m11, m22, m33);
		if big == m11 then
			local s = sqrt(1 + m11 - m22 - m33);
			local r = 0.5 / s;
			return (m32 - m23) * r, Vector3.new(0.5 * s, (m21 + m12) * r, (m13 + m31) * r);
		elseif big == m22 then
			local s = sqrt(1 - m11 + m22 - m33);
			local r = 0.5 / s;
			return (m13 - m31) * r, Vector3.new((m21 + m12) * r, 0.5 * s, (m32 + m23) * r);
		elseif big == m33 then
			local s = sqrt(1 - m11 - m22 + m33);
			local r = 0.5 / s;
			return (m21 - m12) * r, Vector3.new((m13 + m31) * r, (m32 + m23) * r, 0.5 * s);
		end;
	end;
end;
 
local function lerp(a, b, t)
	-- I have no idea what the internal implemenation is
	-- get the difference in CFrames, convert to quaternion, convert to axis angle, slerp
	local cf = a:inverse() * b;
	local w, v = quaternionFromCFrame(cf);
	local theta = acos(w) * 2;
	local p = a.p:Lerp(b.p, t);
	if theta ~= 0 then
		local rot = a * cframe.fromAxisAngle(v, theta * t);
		local _, _, _, m11, m12, m13, m21, m22, m23, m31, m32, m33 = rot:components();
		return cframe.new(p.x, p.y, p.z, m11, m12, m13, m21, m22, m23, m31, m32, m33);
	else
		local _, _, _, m11, m12, m13, m21, m22, m23, m31, m32, m33 = a:components();
		return cframe.new(p.x, p.y, p.z, m11, m12, m13, m21, m22, m23, m31, m32, m33);
	end;
end;
 
-- meta-methods
 
function mt.__index(cf, index)
	if (index == "x" or index == "y" or index == "z") then
		return rawget(cf, "proxy").p[index];
	elseif (index == "p" or index == "lookVector") then
		return rawget(cf, "proxy")[index];
	elseif cframe[index] then
		return cframe[index];
	else
		error(index .. " is not a valid member of CFrame");
	end;
end;
 
function mt.__newindex(v, index, value)
	error(index .. " cannot be assigned to");
end;
 
function mt.__add(a, b)
	local aIsCFrame = type(a) == "table" and a.__type and a.__type == "cframe";
	local bIsCFrame = type(b) == "table" and b.__type and b.__type == "cframe";
	local bIsVector = type(b) == "table" and b.__type and b.__type == "vector3";
	if (aIsCFrame and bIsVector) then
		local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = a:components();	
		return cframe.new(x + b.x, y + b.y, z + b.z, m11, m12, m13, m21, m22, m23, m31, m32, m33);
	elseif (bIsCFrame) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		-- fun fact, you can't add two CFrames so I assume the error code is wrong on this internally ;)
		error("bad argument #2 to '?' (CFrame expected, got " .. cust .. ")");
	elseif (aIsCFrame) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (Vector3 expected, got " .. cust .. ")");
	end;
end;
 
function mt.__sub(a, b)
	local aIsCFrame = type(a) == "table" and a.__type and a.__type == "cframe";
	local bIsCFrame = type(b) == "table" and b.__type and b.__type == "cframe";
	local bIsVector = type(b) == "table" and b.__type and b.__type == "vector3";
	if (aIsCFrame and bIsVector) then
		local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = a:components();	
		return cframe.new(x - b.x, y - b.y, z - b.z, m11, m12, m13, m21, m22, m23, m31, m32, m33);
	elseif (bIsCFrame) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		-- fun fact, you can't add two CFrames so I assume the error code is wrong on this internally ;)
		error("bad argument #2 to '?' (CFrame expected, got " .. cust .. ")");
	elseif (aIsCFrame) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (Vector3 expected, got " .. cust .. ")");
	end;
end;
 
function mt.__mul(a, b)
	local aIsCFrame = type(a) == "table" and a.__type and a.__type == "cframe";
	local bIsCFrame = type(b) == "table" and b.__type and b.__type == "cframe";
	local aIsVector = type(a) == "table" and a.__type and a.__type == "vector3";
	local bIsVector = type(b) == "table" and b.__type and b.__type == "vector3";
	if (aIsCFrame and bIsVector) then
		return cfTimesv3(a, b);
	elseif (aIsCFrame and bIsCFrame) then
		return cfTimescf(a, b);
	elseif (aIsCFrame) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #2 to '?' (Vector3 expected, got " .. cust .. " )");
	elseif (bIsCFrame) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (CFrame expected, got " .. cust .. " )");
	end;
end;
 
function mt.__tostring(t)
	local components = {t:components()};
	if prettyPrint then
		local s = "";
		for i = 1, 12 do 
			s = s .. ((i > 1 and i % 3 == 1 and "\n") or "") .. components[i] .. (i < 12 and ", " or ""); 
		end;
		return s;
	else
		return concat(components, ", ");
	end;
end;
 
mt.__metatable = false;
 
-- public class
 
function cframe.new(...)
	local self = {};
	self.proxy = {};
 
	self.proxy.p = Vector3.new(0, 0, 0);
	for k, v in next, identityMatrix do
		self.proxy[k] = v;
	end;
 
	-- most of this function is error handling from bad userinput
 
	local t = {...};
	local length = #t;
	if length > 12 then
		error("Invalid number of arguments: " .. length);
	elseif (length == 1) then -- single vector3 case
		local v = t[1];
		local isVector = type(v) == "table" and v.__type and v.__type == "vector3";
		if (not isVector) then
			local t = type(v);
			local cust = t == "table" and v.__type or t;
			error("bad argument #1 to 'new' (Vector3 expected, got" .. cust .. ")");
		end;
 
		-- make a copy to avoid user changing the original vector
		self.proxy.p = Vector3.new(v.x, v.y, v.z);
	elseif (length == 2) then -- two vector3 case, we much build a lookAt matrix
		local eye, look = t[1], t[2];
		local eyeIsVector = type(eye) == "table" and eye.__type and eye.__type == "vector3";
		local lookIsVector = type(look) == "table" and look.__type and look.__type == "vector3";
		if (not eyeIsVector and not lookIsVector) then
			local t = type(eye);
			local cust = t == "table" and eye.__type or t;
			error("bad argument #1 to 'new' (Vector3 expected, got" .. cust .. ")");
		end;
 
		local zaxis = (eye - look).unit;
		local xaxis = top:Cross(zaxis).unit;
		local yaxis = zaxis:Cross(xaxis).unit;
		if (xaxis.magnitude == 0) then -- edge cases
			if zaxis.y < 0 then
				xaxis = Vector3.new(0, 0, -1);
				yaxis = Vector3.new(1, 0, 0);
				zaxis = Vector3.new(0, -1, 0);
			else
				xaxis = Vector3.new(0, 0, 1);
				yaxis = Vector3.new(1, 0, 0);
				zaxis = Vector3.new(0, 1, 0);
			end;
		end;
		self.proxy.p = Vector3.new(eye.x, eye.y, eye.z);
		self.proxy.m11, self.proxy.m12, self.proxy.m13 = xaxis.x, yaxis.x, zaxis.x;
		self.proxy.m21, self.proxy.m22, self.proxy.m23 = xaxis.y, yaxis.y, zaxis.y;
		self.proxy.m31, self.proxy.m32, self.proxy.m33 = xaxis.z, yaxis.z, zaxis.z;
	elseif (length == 3) then -- x, y, z
		for i = 1, length do
			local t = type(t[i]);
			local cust = t == "table" and n.__type or t;
			if cust ~= "number" then  error("bad argument #" .. i .. " to 'new' (Number expected, got " .. cust .. ")"); end;
		end;
 
		self.proxy.p = Vector3.new(t[1], t[2], t[3]);
	elseif (length == 7) then -- x, y, z, quaternion
		for i = 1, length do
			local t = type(t[i]);
			local cust = t == "table" and n.__type or t;
			if cust ~= "number" then  error("bad argument #" .. i .. " to 'new' (Number expected, got " .. cust .. ")"); end;
		end;
 
		local m = quaternionToMatrix(t[4], t[5], t[6], t[7]);
		self.proxy.p = Vector3.new(t[1], t[2], t[3]);
		self.proxy.m11, self.proxy.m12, self.proxy.m13 = m[4], m[5], m[6];
		self.proxy.m21, self.proxy.m22, self.proxy.m23 = m[7], m[8], m[9];
		self.proxy.m31, self.proxy.m32, self.proxy.m33 = m[10], m[11], m[12];
	elseif (length ==  12) then -- all components provided
		for i = 1, length do
			local t = type(t[i]);
			local cust = t == "table" and n.__type or t;
			if cust ~= "number" then  error("bad argument #" .. i .. " to 'new' (Number expected, got " .. cust .. ")"); end;
		end;
 
		self.proxy.p = Vector3.new(t[1], t[2], t[3]);
		self.proxy.m11, self.proxy.m12, self.proxy.m13 = t[4], t[5], t[6];
		self.proxy.m21, self.proxy.m22, self.proxy.m23 = t[7], t[8], t[9];
		self.proxy.m31, self.proxy.m32, self.proxy.m33 = t[10], t[11], t[12];
	elseif length > 0 then -- more than zero components
		for i = 1, length do
			local t = type(t[i]);
			local cust = t == "table" and n.__type or t;
			if cust ~= "number" then  error("bad argument #" .. i .. " to 'new' (Number expected, got " .. cust .. ")"); end;
		end;
		error("bad argument #" .. (length + 1) .. " to 'new' (Number expected, got nil)");
	end;
 
	self.proxy.lookVector = Vector3.new(-self.proxy.m13, -self.proxy.m23, -self.proxy.m33);
 
	return setmetatable(self, mt);
end;
 
function cframe.fromAxisAngle(axis, theta)
	local axis = axis.unit;
	local r = fromAxisAngle(axis, right, theta);
	local t = fromAxisAngle(axis, top, theta);
	local b = fromAxisAngle(axis, back, theta);
	return cframe.new(
		0, 0, 0,
		r.x, t.x, b.x,
		r.y, t.y, b.y,
		r.z, t.z, b.z
	);
end;
 
function cframe.Angles(x, y, z)
	-- two implemenations possible. The commented one is what is what is used in the real CFrame constructor (to my knowledge)
	-- the uncommented implemenation is easier for me to keep track of and I think makes more sense, but you can use either
 
	-- the method (presumably) used in the real constructor
	-- How to find this matrix: http://i.imgur.com/IWDMw0m.png
	-- https://en.wikipedia.org/wiki/Rotation_matrix#In_three_dimensions
	--[[
	local m11 = cos(y) * cos(z);
	local m12 = -cos(y) * sin(z);
	local m13 = sin(y);
	local m21 = cos(z) * sin(x) * sin(y) + cos(x) * sin(z);
	local m22 = cos(x) * cos(z) - sin(x) * sin(y) * sin(z); 
	local m23 = -cos(y) * sin(x);
	local m31 = sin(x) * sin(z) - cos(x) * cos(z) * sin(y);
	local m32 = cos(z) * sin(x) + cos(x) * sin(y) * sin(z); 
	local m33 = cos(x) * cos(y);
 
	return cframe.new(0, 0, 0, m11, m12, m13, m21, m22, m23, m31, m32, m33);
	--]]
 
	-- the method I prefer
	local cfx = cframe.fromAxisAngle(right, x);
	local cfy = cframe.fromAxisAngle(top, y);
	local cfz = cframe.fromAxisAngle(back, z);
 
	return cfx * cfy * cfz;
end;
 
function cframe.fromEulerAnglesXYZ(x, y, z)
	return cframe.Angles(x, y, z);
end;
 
function cframe:inverse()
	return invert4x4(self);
end;
 
function cframe:lerp(self2, t)
	return lerp(self, self2, t);
end;
 
function cframe:toWorldSpace(self2)
	return self * self2;
end;
 
function cframe:toWorldSpace(self2)
	return self * self2;
end;
 
function cframe:toObjectSpace(self2)
	return self:inverse() * self2;
end;
 
function cframe:pointToWorldSpace(v3)
	return self * v3;
end;
 
function cframe:pointToObjectSpace(v3)
	return self:inverse() * v3;
end;
 
function cframe:vectorToWorldSpace(v3)
	return (self - self.p) * v3;
end;
 
function cframe:vectorToObjectSpace(v3)
	return (self - self.p):inverse() * v3;
end;
 
function cframe:components()
	local m = rawget(self, "proxy");
	return m.p.x, m.p.y, m.p.z, m.m11, m.m12, m.m13, m.m21, m.m22, m.m23, m.m31, m.m32, m.m33;
end;
 
function cframe:toEulerAnglesXYZ()
	-- based off the method (presumably) used in the real constructor for cframe.Angles
	local _, _, _, m11, m12, m13, m21, m22, m23, m31, m32, m33 = self:components();
	local x = atan2(-m23, m33);
	local y = asin(m13);
	local z = atan2(-m12, m11);
	return x, y, z;
end;
 
return cframe;