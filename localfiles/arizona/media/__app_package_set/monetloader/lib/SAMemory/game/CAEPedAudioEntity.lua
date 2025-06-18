--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
  Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CAESound'
shared.require 'CAEAudioEntity'
shared.require 'CAETwinLoopSoundEntity'

shared.ffi.cdef[[
	typedef struct CPed CPed;

	typedef struct CAEPedAudioEntity : CAEAudioEntity
	{
    /*
    ORIGINAL GTA STRUCT:
    Bool8 m_bInitialised;
    int16 m_nLastSwimSplashSoundID;
    UInt32 m_nLastSwimWakeTriggerTimeMs;
    float m_fCurrentJetPackThrustVolume;
    float m_fCurrentJetPackGasVolume;
    float m_fCurrentJetPackRoarVolume;
    float m_fCurrentJetPackRoarFrequency;
    CPed *m_pParentPed;
    Bool8 m_bJetPackOn;
    CAESound *m_pJetPackThrustSound;
    CAESound *m_pJetPackGasSound;
    CAESound *m_pJetPackRoarSound;
    CAETwinLoopSoundEntity m_ShirtFlapTwinLoopSound;
    CAESound *m_pWindRushSound;
    float m_fCurrentWindRushVolume;
    float m_fCurrentShirtFlapVolume;
    */
		char 						field_7C;
    short 					field_7E;
    unsigned int 		field_80;
    float 					field_84;
    float 					field_88;
    float           field_8C;
    float           field_90;
    CPed 						*pPed;
    char 						field_98;
    CAESound 				*field_9C;
    CAESound 				*field_A0;
    CAESound 				*field_A4;
		CAETwinLoopSoundEntity nTwinLoopSoundEntity;
    CAESound 				*field_150;
    float 					field_154;
    float 					field_158;
	} CAEPedAudioEntity;
]]

--shared.validate_size('CAEPedAudioEntity', 0x15C)
