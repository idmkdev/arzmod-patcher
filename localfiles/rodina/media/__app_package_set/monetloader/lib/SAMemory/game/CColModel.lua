--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CCollisionData'
shared.require 'RenderWare'

shared.ffi.cdef[[
	typedef struct CColModel
	{
		RwBBox 					nBoundBox;
		RwSphere   			nBoundSphere;
		unsigned char   nLevel;
		unsigned char   bHasCollisionVolumes : 1;
		unsigned char   bUseSingleAlloc : 1;
		unsigned char   bDeleteUncompressed : 1;
		CCollisionData  *pColData;
	} CColModel;
]]

--shared.validate_size('CColModel', 0x30)
