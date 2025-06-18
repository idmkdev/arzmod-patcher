--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.ffi.cdef[[
	typedef struct CColTriangle
	{
		unsigned int   nVertA;
		unsigned int   nVertB;
		unsigned int   nVertC;
		unsigned char  nMaterial;
		unsigned char  nLight;
	} CColTriangle;
]]

--shared.validate_size('CColTriangle', 8)
