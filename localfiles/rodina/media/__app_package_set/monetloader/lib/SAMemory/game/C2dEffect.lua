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
shared.require 'vector2d'
shared.require 'vector3d'

shared.ffi.cdef[[
	typedef enum e2dEffectType
	{
		EFFECT_LIGHT,
		EFFECT_PARTICLE,
		EFFECT_ATTRACTOR = 3,
		EFFECT_SUN_GLARE,
		EFFECT_FURNITUR,
		EFFECT_ENEX,
		EFFECT_ROADSIGN,
		EFFECT_SLOTMACHINE_WHEEL,
		EFFECT_COVER_POINT,
		EFFECT_ESCALATOR,
	} e2dEffectType;

	typedef enum ePedAttractorType
	{
		PED_ATTRACTOR_ATM            = 0,
		PED_ATTRACTOR_SEAT           = 1,
		PED_ATTRACTOR_STOP           = 2,
		PED_ATTRACTOR_PIZZA          = 3,
		PED_ATTRACTOR_SHELTER        = 4,
		PED_ATTRACTOR_TRIGGER_SCRIPT = 5,
		PED_ATTRACTOR_LOOK_AT        = 6,
		PED_ATTRACTOR_SCRIPTED       = 7,
		PED_ATTRACTOR_PARK           = 8,
		PED_ATTRACTOR_STEP           = 9
	} ePedAttractorType;

	typedef struct tEffectLight
	{
		RwColor color;
		float fCoronaFarClip;
		float fPointlightRange;
		float fCoronaSize;
		float fShadowSize;
		unsigned short nFlags;
		unsigned char nCoronaFlashType;
		bool bCoronaEnableReflection;
		unsigned char nCoronaFlareType;
		unsigned char nShadowColorMultiplier;
		unsigned char nShadowZDistance;
		char offsetX;
		char offsetY;
		char offsetZ;
		RwTexture *pCoronaTex;
		RwTexture *pShadowTex;
	} tEffectLight;

	typedef struct tEffectParticle
	{
		char szName[24];
	} tEffectParticle;

	typedef struct tEffectPedAttractor
	{
		vector3d vecQueueDir;
		vector3d vecUseDir;
		vector3d vecForwardDir;
		unsigned char nAttractorType;
		unsigned char nPedExistingProbability;
		unsigned char field_36; // uint8 m_lookAt
		unsigned char nFlags;
		char szScriptName[8];
	} tEffectPedAttractor;

	typedef struct tEffectEnEx
	{
		float fEnterAngle;
		// incorrect struct fixed
		float wx;
		float wy;
		float spawnx;
		float spawny;
		float spawnz;
		float spawnrot;
		float fExitAngle;
		short nInteriorId;
		unsigned char nFlags1;
		unsigned char nSkyColor;
		char szInteriorName[8];
		unsigned char nTimeOn;
		unsigned char nTimeOff;
		unsigned char nFlags2;
	} tEffectEnEx;

	typedef struct tEffectRoadsign
	{
		vector2d vecSize;
		float afRotation[3];
		unsigned short nFlags;
		char *pText;
		RpAtomic *pAtomic;
	} tEffectRoadsign;

	typedef struct tEffectCoverPoint
	{
		vector2d vecDirection;
		char nType;
	} tEffectCoverPoint;

	typedef struct tEffectEscalator
	{
		vector3d vecBottom;
		vector3d vecTop;
		vector3d vecEnd;
		unsigned char nDirection; // bool bGoingUp
	} tEffectEscalator;

	typedef struct C2dEffect
	{
		vector3d vecPosn;
		uint8_t nType;
		union
		{
			tEffectLight light;
			tEffectParticle particle;
			tEffectPedAttractor pedAttractor;
			tEffectEnEx enEx;
			tEffectRoadsign roadsign;
			tEffectCoverPoint coverPoint;
			tEffectEscalator escalator;
		};
	} C2dEffect;
]]

--shared.validate_size('C2dEffect', 0x40)