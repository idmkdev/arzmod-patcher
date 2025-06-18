--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CTaskTimer'
shared.require 'CAttractorScanner'

shared.ffi.cdef[[
	typedef struct CEventScanner
	{
		/*
		ORIGINAL GTA STRUCT:
		int32 m_startTime;
		CVehiclePotentialCollisionScanner m_vehicleCollisionScanner; // only a CTaskTimer
		CObjectPotentialCollisionScanner m_objectCollisionScanner; // only a CTaskTimer
		CAttractorScanner m_attractorScanner;
		CPedAcquaintanceScanner m_acquaintanceScanner;
		CSexyPedScanner m_sexyPedScanner; // only a CTaskTimer
		CNearbyFireScanner m_fireScanner; // only a CTaskTimer

		CPedAcquaintanceScanner
		----
		CTaskTimer m_timer;
		bool m_bActivatedEverywhere;
		bool m_bActivatedInVehicle;
		bool m_bActivatedDuringScriptCommands;
		*/
		int field_0;
		CTaskTimer field_4;
		CTaskTimer field_10;
		CAttractorScanner m_attractorScanner;

		CTaskTimer field_AC;
		char field_B8;
		char field_B9;
		char field_BA;

		CTaskTimer field_BC;
		CTaskTimer field_C8;
	} CEventScanner;
]]

--shared.validate_size('CEventScanner', 0xD4)
