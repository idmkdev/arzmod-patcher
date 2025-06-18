--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'vector3d'

shared.ffi.cdef[[
	typedef struct CColTrianglePlane
	{
		vector3d         normal;
		float            nDistance;
		unsigned char 	 nOrientation;
	} CColTrianglePlane;
]]

--shared.validate_size('CColTrianglePlane', 0xA)
