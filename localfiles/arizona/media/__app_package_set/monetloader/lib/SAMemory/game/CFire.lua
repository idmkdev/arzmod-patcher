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
shared.require 'CEntity'
shared.require 'FxSystem_c'

shared.ffi.cdef[[
	typedef struct CFire
	{
		struct
		{
			unsigned char bActive : 1;
			unsigned char bCreatedByScript : 1;
			unsigned char bMakesNoise : 1;
			unsigned char bBeingExtinguished : 1;
			unsigned char bFirstGeneration : 1;
		} nFlags;
		short nScriptReferenceIndex;
		vector3d vecPosition;
		CEntity *pEntityTarget;
		CEntity *pEntityCreator;
		unsigned int nTimeToBurn;
		float fStrength;
		char nNumGenerationsAllowed;
		unsigned char nRemovalDist;
		FxSystem_c *pFxSystem;
	} CFire;
]]

--shared.validate_size('CFire', 0x28)
