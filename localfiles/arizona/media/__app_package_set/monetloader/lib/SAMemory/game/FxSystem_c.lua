--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CAEAudioEntity'
shared.require 'RenderWare'
shared.require 'vector3d'
shared.require 'CEntity'

shared.ffi.cdef[[
	typedef enum eFxSystemKillStatus
	{
		FX_NOT_KILLED = 0,
		FX_PLAY_AND_KILL = 1,
		FX_KILLED = 2
	} eFxSystemKillStatus;

	typedef enum eFxSystemPlayStatus
	{
		FX_PLAYING = 0,
		FX_STOPPED = 1
	} eFxSystemPlayStatus;

	// Struct is totally wrong.

	typedef struct FxSystem_c FxSystem_c;
	typedef struct CAEFireAudioEntity : CAEAudioEntity
	{
		CAESound *m_pFireSound;
		CAESound *m_pFireSound2;
		FxSystem_c *m_pParentEffectSystem;
	} CAEFireAudioEntity;

	typedef struct ListItem_c
	{
		struct ListItem_c* m_prev;
		struct ListItem_c* m_next;
	} ListItem_c;

	typedef struct FxSystem_c : ListItem_c
	{
		void 						*pBlueprint;
		RwMatrix 				*pParentMatrix;
		CEntity         *pEntity;
		RwMatrix 				localMatrix;
		char 	          nPlayStatus;
		char 	          nKillStatus;
		unsigned char 	bConstTimeSet;
		float           fCurrTime;
		float 					fCameraDistance;
		unsigned short 	nConstTime;
		unsigned short 	nRateMult;
		unsigned short 	nTimeMult;
		struct
		{
			unsigned char bOwnedParentMatrix: 1;
			unsigned char blocalParticles : 1;
			unsigned char bZTestEnabled : 1;
			unsigned char bUnknown4 : 1; // stopParticleCreation
			unsigned char bUnknown5 : 1; // prevCulled
			unsigned char bMustCreatePtrs : 1;
		} nFlags;
		float 					fUnkRandom; // m_loopInterval
		vector3d 				vecVelAdd;
		void 						*pBounding;
		void 						**pPrimsPtrList;
		CAEFireAudioEntity fireAudioEntity;
	} FxSystem_c;
]]
