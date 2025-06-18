--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

require 'SAMemory.game.vector3d'
require 'SAMemory.game.RenderWare'

local mt = require 'SAMemory.metatype'
local ffi = require 'ffi'

ffi.cdef[[
	typedef struct _quaternion
	{
		vector3d imag;
		float 	 real;
	} quaternion;


]]

local function copysign(value, sign)
	if value < 0 and sign < 0 then
		return value
	elseif value >= 0 and sign < 0 then
		return -value
	elseif value < 0 and sign >= 0 then
		return -value
	elseif value >= 0 and sign >= 0 then
		return value
	end
end

local function quaternion(imag, real)
	return ffi.new('quaternion', imag, real)
end

-- moved into lua by monetloader
local quat = {
	dot_product	 = function(a, b)
		return a.imag.x * b.imag.x + a.imag.y * b.imag.y + a.imag.z * b.imag.z + a.real * b.real
	end,
	set_matrix 	 = function(self, mat)
		self.real   = math.sqrt(math.max(0.0, 1.0 + mat.right.x + mat.up.y + mat.at.z)) * 0.5
		self.imag.x = math.sqrt(math.max(0.0, 1.0 + mat.right.x - mat.up.y - mat.at.z)) * 0.5
		self.imag.y = math.sqrt(math.max(0.0, 1.0 - mat.right.x + mat.up.y - mat.at.z)) * 0.5
		self.imag.z = math.sqrt(math.max(0.0, 1.0 - mat.right.x - mat.up.y + mat.at.z)) * 0.5

		self.imag.x = copysign(x, mat.at.y - mat.up.z)
		self.imag.y = copysign(y, mat.right.z - mat.at.x)
		self.imag.z = copysign(z, mat.up.x - mat.right.y)
	end,
	normalize		 = function(self)
		local sq = self:dot_product(self) -- length^2 = dot_product(a, a)
		if sq == 0.0 then
			self.real = 1.0
		else
			local recip = 1.0 / math.sqrt(sq)
			self.real   = self.real   * recip
			self.imag.x = self.imag.x * recip
			self.imag.y = self.imag.y * recip
			self.imag.z = self.imag.z * recip
		end
	end,
	slerp				 = function(self, a, b, t)
		local theta = math.acos(math.min(1.0, a:dot_product(b)))
		if theta == 0.0 then
			self:copy(b)
			return
		end

		local invsin = 1.0 / math.sin(theta)
		local w1 = 0.0
		local w2 = 0.0

		if theta > math.pi * 0.5 then
			theta = math.pi - theta
			w1 = math.sin((1.0 - t) * theta) * invsin
			w2 = -math.sin(t * theta) * invsin
		else
			w1 = math.sin((1.0 - t) * theta) * invsin
			w2 = math.sin(t * theta) * invsin
		end

		self.real   = a.real   * w1 + b.real   * w2
		self.imag.x = a.imag.x * w1 + b.imag.x * w2
		self.imag.y = a.imag.y * w1 + b.imag.y * w2
		self.imag.z = a.imag.z * w1 + b.imag.z * w2
	end,
	copy 				 = function(self, other)
		self.real = other.real
		self.imag.x = other.imag.x
		self.imag.y = other.imag.y
		self.imag.z = other.imag.z
	end
}

function quat:get_matrix()
	local matrix = ffi.new('RwMatrix') -- SAMemory bug: allocation of pointer instead of matrix

	local x2 = self.imag.x + self.imag.x
	local y2 = self.imag.y + self.imag.y
	local z2 = self.imag.z + self.imag.z

	local x_2x = self.imag.x * x2
	local x_2y = self.imag.x * y2
	local x_2z = self.imag.x * z2

	local y_2y = self.imag.y * y2
	local y_2z = self.imag.y * z2

	local z_2z = self.imag.z * z2

	local w_2x = self.real * x2
	local w_2y = self.real * y2
	local w_2z = self.real * z2

	matrix.right.x = 1.0 - (y_2y + z_2z)
	matrix.right.y = x_2y + w_2z
	matrix.right.z = x_2z - w_2y

	matrix.up.x = x_2y - w_2z
	matrix.up.y = 1.0 - (x_2x + z_2z)
	matrix.up.z = y_2z + w_2x

	matrix.at.x = x_2z + w_2y
	matrix.at.y = y_2z - w_2x
	matrix.at.z = 1.0 - (x_2x + y_2y)

	return matrix
end

quat.DotProduct = quat.dot_product
quat.SetMatrix  = quat.set_matrix
quat.GetMatrix  = quat.get_matrix

mt.provide_access('quaternion', quat, true, false)

return {
	new = quaternion;
}
