--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'RenderWare'
shared.require 'CEntity'
shared.require 'CAutomobile'
shared.require 'FxSystem_c'

shared.ffi.cdef[[
	typedef struct CPlane : CAutomobile
	{
		/*
		ORIGINAL GTA STRUCT:
		float m_fYawControl;
		float m_fPitchControl;
		float m_fRollControl;
		float m_fThrottleControl;
		float m_fScriptThrottleControl;
		float m_fPreviousRoll;
		uint32 m_nStallCounter;
		float m_TakeOffDirection;
		float m_LowestFlightHeight;
		float m_DesiredHeight;
		float m_MinHeightAboveTerrain;
		float m_FlightDirection;
		float m_FlightDirectionAvoidingTerrain;
		float m_OldTilt;
		UInt32 m_OnGroundTimer;
		float m_fEngineSpeed;
		float m_fPropellerAngle;
		float m_fLGearAngle;
		uint32 m_nDamageControlWaveCounter;
		FxSystem_c **m_GunflashFxPtrs;
		uint8 m_FiringRateMultiplier;
		uint32 m_FireMissilePressedTime;
		CEntity *m_pLastMissileTarget;
		unsigned __int32 m_LastHSMissileLOSTime : 31;
		unsigned __int32 m_bLastHSMissileLOS : 1;
		FxSystem_c *m_fxSysNozzle[4];
		FxSystem_c *m_fxSysFire;
		int32 m_fireTime;
		bool8 m_fxActive;
		*/
		float 				field_988;
		float 				field_98C;
		float 				field_990;
		float					field_994;
		float 				field_998;
		float					field_99C;
		unsigned int 	field_9A0;
		float					field_9A4;
		float 				field_9A8;
		float 				field_9AC;
		float 				field_9B0;
		float 				field_9B4;
		float					field_9B8;
		float 				field_9BC;
		unsigned int 	nStartedFlyingTime;
		float 				field_9C4;
		float 				field_9C8;
		float 				fLandingGearStatus;
		unsigned int 	field_9D0;
		FxSystem_c 		**pGunParticles;
		unsigned char nFiringMultiplier;
		unsigned int 	field_9DC;
		CEntity       *field_9E0;
		unsigned int 	field_9E4;
		FxSystem_c 		*apJettrusParticles[4];
		FxSystem_c 		*pSmokeParticle;
		unsigned int 	nSmokeTimer;
		bool 					bSmokeEjectorEnabled;
	} CPlane;
]]

--shared.validate_size('CPlane', 0xA04)
