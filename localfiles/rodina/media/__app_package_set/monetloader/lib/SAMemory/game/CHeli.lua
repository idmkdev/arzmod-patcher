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
shared.require 'CAutomobile'
shared.require 'FxSystem_c'

shared.ffi.cdef[[
	typedef struct CHeli : CAutomobile
	{
		union
		{
			unsigned char               nHeliFlags;
			struct
			{
        unsigned char bStopFlyingForAWhile : 1;
				unsigned char bUseSearchLightOnTarget : 1;
				unsigned char bWarnTarger : 1;
			} heliFlags;
		};
		float              fLeftRightSkid; // m_fYawControl
		float              fSteeringUpDown; // m_fPitchControl
		float              fSteeringLeftRight; // m_fRollControl
		float              fAccelerationBreakStatus; // m_fThrottleControl
		float 						 field_99C; // m_fEngineSpeed
		float              fRotorZ;
		float              fSecondRotorZ;
		float              fMaxAltitude;
		float 						 field_9AC; // m_fDesiredHeight
		float              fMinAltitude;
		float 						 field_9B4; // m_FlightDirection
		char 							 field_9B8; // m_bStopFlyingForAWhile
		unsigned char      nNumSwatOccupants;
		unsigned char      anSwatIDs[4]; // m_SwatRopeActive
		float              afOldSearchLightX[6];
    float              afOldSearchLightY[6];
		unsigned int 			 field_9F0; // m_LastSearchLightSample
		vector3d           vSearchLightTarget;
		float              fSearchLightIntensity;
		unsigned int 			 field_A04; // m_LastTimeSearchLightWasTooFarAwayToShoot
		unsigned int 			 field_A08; // m_nNextTalkTimer
		FxSystem_c         **ppGunflashFx;
		unsigned char      nFiringMultiplier;
		char               bSearchLightEnabled;
		float 						 field_A14; // m_crashAndBurnTurnSpeed
	} CHeli;
]]

--shared.validate_size('CHeli', 0xA18)
