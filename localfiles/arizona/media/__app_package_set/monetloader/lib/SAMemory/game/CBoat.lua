--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'vector2d'
shared.require 'RenderWare'
shared.require 'CVehicle'
shared.require 'CEntity'
shared.require 'CDoor'
shared.require 'FxSystem_c'
shared.require 'tBoatHandlingData'
shared.require 'vector3d'

shared.ffi.cdef[[
	typedef enum eBoatNodes
	{
		BOAT_NODE_NONE = 0,
		BOAT_MOVING = 1,
		BOAT_WINDSCREEN = 2,
		BOAT_RUDDER = 3,
		BOAT_FLAP_LEFT = 4,
		BOAT_FLAP_RIGHT = 5,
		BOAT_REARFLAP_LEFT = 6,
		BOAT_REARFLAP_RIGHT = 7,
		BOAT_STATIC_PROP = 8,
		BOAT_MOVING_PROP = 9,
		BOAT_STATIC_PROP_2 = 10,
		BOAT_MOVING_PROP_2 = 11,
		BOAT_NUM_NODES
	} eBoatNodes;

	typedef struct CBoat : CVehicle
	{
		float              fMovingHiRotation;
		float              fPropSpeed;
		float              fPropRotation;
		struct
		{
			unsigned char bOnWater : 1;
			unsigned char bMovingOnWater : 1;
			unsigned char bAnchored : 1;
		} nBoatFlags;
		unsigned char       nCurrentLOD;
		RwFrame            	*pBoatNodes[12];
		CDoor              	boatFlap;
		tBoatHandlingData 	*pBoatHandling;
		float              	fAnchoredAngle;
		unsigned int        nAttackPlayerTime; // m_nNextTalkTimer
		unsigned int 				field_604; // TimeOfLastParticle
		float              	fBurningTimer;
		CEntity           	*pWhoDestroyedMe;
		vector3d            vBoatMoveForce; // OLD
		vector3d            vBoatTurnForce; // OLD
		FxSystem_c        	*apPropSplashFx[2];
		vector3d            vWaterDamping;
		unsigned char 			field_63C; // nCurrentField
		unsigned char      	nPadNumber;
		float              	fWaterResistance; // fPrevVolume
		short              	nNumWaterTrailPoints;
		vector2d          	avWakePoints[32];
		float              	afWakePointLifeTime[32];
		unsigned char      	anWakePointIntensity[32];
	} CBoat;
]]

--shared.validate_size('CBoat', 0x7E8)
