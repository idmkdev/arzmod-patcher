--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CEntity'

shared.ffi.cdef[[
	typedef struct CEntityScanner
	{
		void 						*vptr;
		int 						field_4; // CTickCounter::m_iCount
		int   	        nCount; // WRONG: CTickCounter::m_iPeriod
		CEntity		 			*apEntities[16];
		CEntity 				*field_4C; // pClosestEntity
	} CEntityScanner;
]]

--shared.validate_size('CEntityScanner', 0x50)
