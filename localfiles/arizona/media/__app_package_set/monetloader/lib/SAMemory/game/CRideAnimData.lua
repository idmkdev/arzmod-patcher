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
	typedef struct CRideAnimData
	{
		unsigned int nAnimGroup;
		float 			 dword4; // m_fBarSteerAngle
		float        fAnimLean;
		float 			 dwordC; // m_fDesiredLeanAngle
		float 			 dword10; // m_fLeanFwd
		float        fHandlebarsAngle; // m_fAnimLeanLeft
		float        fAnimPercentageState; // m_fAnimLeanFwd
	} CRideAnimData;
]]

--shared.validate_size('CRideAnimData', 0x1C)
