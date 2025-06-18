--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CPed'

shared.ffi.cdef[[
	typedef enum eCopType
	{
		COP_TYPE_CITYCOP,
		COP_TYPE_LAPDM1,
		COP_TYPE_SWAT1,
		COP_TYPE_SWAT2,
		COP_TYPE_FBI,
		COP_TYPE_ARMY,
		COP_TYPE_CSHER = 7
	} eCopType;

	typedef struct CCopPed CCopPed;

	struct CCopPed : CPed
	{
		bool          bRoadBlockCop;
    bool          bRemoveIfNonVisible;
		unsigned int  copType;
    int 					field_7A4; // m_nStuckCounter
		CCopPed       *pCopPartner;
		CPed          *apCriminalsToKill[5];
		char 					field_7C0; // m_bIAmDriver
	};
]]

--shared.validate_size('CCopPed', 0x7C4)
