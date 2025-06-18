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

shared.ffi.cdef[[
	typedef enum eAudioPedType
	{
		PED_TYPE_GEN = 0,
		PED_TYPE_EMG = 1,
		PED_TYPE_PLAYER = 2,
		PED_TYPE_GANG = 3,
		PED_TYPE_GFD = 4,
		PED_TYPE_SPC = 5
	} eAudioPedType;

	typedef struct CAEPedSpeechAudioEntity : CAEAudioEntity
	{
		/*
		ORIGINAL GTA STRUCT:
		CAESound *SoundPtrs[5];
		Bool8 b_Initialised;
		Int16 m_PedType;
		Int16 m_VoiceID;
		Int16 m_bFemale;
		Bool8 m_bPlayingSpeech;
		Bool8 m_bSpeechDisabled;
		Bool8 m_bSpeechDisabledForScriptSpeech;
		Bool8 m_bFrontEnd;
		Bool8 m_bForceAudible;
		CAESound *m_pSound;
		Int16 m_SoundID;
		Int16 m_BankID;
		Int16 m_PedSpeechSlotID;
		float m_fEventVolume;
		Int16 m_LastUsedGlobalSpeechContext;
		UInt32 m_NextTimeCanSayPain[19];
	  */
		CAESound       *field_7C[5];
		char 						field_90;
		short 					nVoiceType;
		short 					nVoiceID;
		short 					nVoiceGender;
		char 						field_98;
		bool 						bEnableVocalType;
		bool 						bMuted;
		char 						nVocalEnableFlag;
		char 						field_9C;
		CAESound 				*pSound;
		short 					field_A4;
		short 					field_A6;
		short 					field_A8;
		float 					fVoiceVolume;
		short 					nCurrentPhraseId;
		unsigned int 		field_B4[19];
	} CAEPedSpeechAudioEntity;
]]

--shared.validate_size('CAEPedSpeechAudioEntity', 0x100)
