--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared  = require 'SAMemory.shared'

shared.require 'RenderWare'

shared.ffi.cdef[[
	typedef struct CColBox : RwBBox
	{
		unsigned char nMaterial;
		unsigned char nFlags;
		unsigned char nLighting;
	} CColBox;
]]

--shared.validate_size('CColBox', 0x1C)
