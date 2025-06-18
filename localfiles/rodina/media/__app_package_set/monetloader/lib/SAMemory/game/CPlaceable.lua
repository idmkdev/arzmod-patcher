--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
]]
local shared = require 'SAMemory.shared'

shared.require 'matrix'
shared.require 'CSimpleTransform'

shared.ffi.cdef[[
	typedef struct CPlaceable
	{
		void							*vptr;
		CSimpleTransform 	nPlacement;
		matrix            *pMatrix;
	} CPlaceable;
]]

--shared.validate_size('CPlaceable', 0x18)
