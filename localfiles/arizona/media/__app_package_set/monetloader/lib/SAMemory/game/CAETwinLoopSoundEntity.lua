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
shared.require 'CAESound'

shared.ffi.cdef[[
	typedef struct CAETwinLoopSoundEntity : CAEAudioEntity
	{
    /*
    ORIGINAL GTA STRUCT:
    Int16 m_BankSlotID;
    Int16 m_FirstSoundID;
    Int16 m_SecondSoundID;
    CAEAudioEntity *m_pAudioEntity;
    Bool16 m_bCurrentlyInUse;
    Int16 m_nFirstLength;
    Int16 m_nSecondLength;
    UInt16 m_MinSwapTime;
    UInt16 m_MaxSwapTime;
    UInt32 m_SwapTime;
    Bool8 m_bPlayingFirst;
    Int16 m_StartPercentFirst;
    Int16 m_StartPercentSecond;
    CAESound *m_pFirstSoundPtr;
    CAESound *m_pSecondSoundPtr;
    */
		short           nBankSlotId;
    short           nSoundType[2];
    CAEAudioEntity  *pBaseAudio;
    short 					field_88;
    short 					field_8A;
    short 					field_8C;
    unsigned short  nPlayTimeMin;
    unsigned short  nPlayTimeMax;
    unsigned int    nTimeToSwapSounds;
    bool            bPlayingFirstSound;
    short           anStartingPlayPercentage[2];
    CAESound        *apSounds[2];
	} CAETwinLoopSoundEntity;
]]

--shared.validate_size('CAETwinLoopSoundEntity', 0xA8)
