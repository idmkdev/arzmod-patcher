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
	typedef struct tVehicleSound
	{
    short         nIndex;
    CAESound     *pSound;
	} tVehicleSound;

	typedef struct tVehicleAudioSettings
	{
    /*
    ORIGINAL GTA STRUCT:
    Int8 VehicleAudioType;
    int16 PlayerBank;
    int16 DummyBank;
    Int8 BassSetting;
    float BassFactor;
    float EnginePitch;
    Int8 HornType;
    float HornPitch;
    Int8 DoorType;
    Int8 EngineUpgrade;
    Int8 RadioStation;
    Int8 RadioType;
    Int8 VehicleAudioTypeForName;
    float EngineVolumeOffset;
    */
		char  nVehicleSoundType;
	  short nEngineOnSoundBankId;
	  short nEngineOffSoundBankId;
	  char  nStereo;
	  float fBassFactor;
	  float fEnginePitch;
	  char  bHornTon;
	  float fHornHigh;
	  char  nDoorSound;
	  char field_19;
	  char  nRadioNum;
	  char  nRadioType;
	  char field_1C;
	  float fHornVolumeDelta;
	} tVehicleAudioSettings;

	typedef struct CAEVehicleAudioEntity : CAEAudioEntity
	{
    /*
    ORIGINAL GTA STRUCT:
    Int16 m_nStallCounter;
    tVehicleAudioSettings m_VehicleAudioSetting;
    Bool8 m_bInitialised;
    Bool8 m_bPlayerDriven;
    Bool8 m_bPlayerOnlyAttached;
    Bool8 m_bPlayerDriverAboutToExit;
    Bool8 m_bWreckedVehicle;
    Int8 m_State;
    UInt8 m_AudioGear;
    float m_CrzCount;
    Bool8 m_bSingleGear;
    Int16 m_nRainHitCount;
    Int16 m_nStalledCount;
    UInt32 m_nSwapStalledTime;
    Bool8 m_bSilentStalled;
    Bool8 m_bHelicoptorDisabled;
    Bool8 m_bHornOn;
    Bool8 m_bSirenOn;
    Bool8 m_bFastSirenOn;
    float m_HornVolume;
    Bool8 m_bUsesSiren;
    UInt32 m_TimeSplashLastTriggered;
    UInt32 m_TimeBeforeAllowAccelerate;
    UInt32 m_TimeBeforeAllowCruise;
    float m_fEventVolume;
    Int16 m_DummyEngineBank;
    Int16 m_PlayerEngineBank;
    Int16 m_DummySlot;
    tEngineSound m_EngineSounds[12];
    UInt32 m_TimeLastServiced;
    Int16 m_ACPlayPositionThisFrame;
    Int16 m_ACPlayPositionLastFrame;
    Int16 m_FramesAgoACLooped;
    Int16 m_ACPlayPercentWhenStopped;
    UInt32 m_TimeACStopped;
    Int16 m_ACPlayPositionWhenStopped;
    Int16 m_SurfaceSoundID;
    CAESound *m_SurfaceSoundPtr;
    Int16 m_RoadNoiseSoundID;
    CAESound *m_RoadNoiseSoundPtr;
    Int16 m_FlatTyreSoundID;
    CAESound *m_FlatTyreSoundPtr;
    Int16 m_ReverseSoundID;
    CAESound *m_ReverseSoundPtr;
    Int16 m_HornSoundID;
    CAESound *m_HornSoundPtr;
    CAESound *m_SirenSoundPtr;
    CAESound *m_FastSirenSoundPtr;
    CAETwinLoopSoundEntity m_SkidSound;
    float m_CurrentRotorFrequency;
    float m_CurrentDummyEngineVolume;
    float m_CurrentDummyEngineFrequency;
    float m_fMovingPartSmoothedSpeed;
    float m_fFadeIn;
    float m_fFadeOut;
    Bool8 m_bNitroOnLastFrame;
    float m_CurrentNitroRatio;
    */
		short 									field_7C;
    tVehicleAudioSettings   settings;
    bool                    bEnabled;
    bool                    bPlayerDriver;
    bool                    bPlayerPassenger;
    bool                    bVehicleRadioPaused;
    bool                    bSoundsStopped;
    char                    nEngineState;
    unsigned char 					field_AA;
    float										fCrzCount;
    bool                    bInhibitAccForLowSpeed;
    short                   nRainDropCounter;
    short 									field_B4;
    unsigned int 						field_B8;
    char 										field_BC;
    bool                    bDisableHeliEngineSounds;
    char 										field_BE;
    bool                    bSirenOrAlarmPlaying;
    bool                    bHornPlaying;
    float                   fSirenVolume;
    bool                    bModelWithSiren;
    unsigned int            nBoatHitWaveLastPlayedTime;
    unsigned int            nTimeToInhibitAcc;
    unsigned int            nTimeToInhibitCrz;
    float                   fGeneralVehicleSoundVolume;
    short                   nEngineDecelerateSoundBankId;
    short                   nEngineAccelerateSoundBankId;
    short                   nEngineBankSlotId;
    tVehicleSound           aEngineSounds[12];
    unsigned int 						field_144;
    short 									field_148;
    short 									field_14A;
    short 									field_14C;
    short 									field_14E;
    unsigned int 						field_150;
    short 									field_154;
    short                   nSkidSoundType;
    CAESound 								*field_158;
    short                   nRoadNoiseSoundType;
    CAESound                *pRoadNoiseSound;
    short                   nFlatTyreSoundType;
    CAESound                *pFlatTyreSound;
    short                   nReverseGearSoundType;
    CAESound                *pReverseGearSound;
    short                   nHornTonSoundType;
    CAESound                *pHornTonSound;
    CAESound                *pSirenSound;
    CAESound                *pPoliceSirenSound;
    CAETwinLoopSoundEntity  skidSound;
    float 									field_22C;
    float 									field_230;
    float 									field_234;
    float 									field_238;
    float 									field_23C;
    int 										field_240;
    bool                    bNitroSoundPresent;
    float 									field_248;
	} CAEVehicleAudioEntity;
]]

--shared.validate_size('CAEVehicleAudioEntity', 0x24C)
