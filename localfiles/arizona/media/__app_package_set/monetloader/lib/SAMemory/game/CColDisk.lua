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
shared.require 'CColSphere'

shared.ffi.cdef[[
	typedef struct CColDisk : CColSphere
	{
		vector3d VecEnd; // m_vecThickness
		float fEndRadius; // m_fThickness
	} CColDisk;
]]

--shared.validate_size('CColDisk', 0x24)
