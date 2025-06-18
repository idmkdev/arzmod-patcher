--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CBike'

shared.ffi.cdef[[
	typedef struct CBmx : CBike
	{
		float 				field_814; // m_fControlJump
		float 				field_818; // m_fControlPedaling
		float 				field_81C; // m_fSprintLeanAngle
		float 				field_820; // m_fCrankAngle
		float 				field_824; // m_fPedalAngleL
		float 				field_828; // m_fPedalAngleR
		float 				fDistanceBetweenWheels;
		float 				fWheelsBalance;
		unsigned char field_834; // m_bIsFreewheeling
	} CBmx;
]]

--shared.validate_size('CBmx', 0x838)
