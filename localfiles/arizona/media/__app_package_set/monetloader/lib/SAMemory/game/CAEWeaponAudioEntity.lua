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
shared.require 'CPed'

shared.ffi.cdef[[
	/*
		INVALID NAME: In original GTA there are two separate classes: CAEPedWeaponAudioEntity and CAEWeaponAudioEntity.
		This is CAEPedWeaponAudioEntity.
	*/

	// CAEWeaponAudioEntity
	typedef struct CAEWeaponAudioEntity__Base : CAEAudioEntity
	{
		/*
		ORIGINAL GTA STRUCT:
		Bool8 m_bMiniGunSpinActive;
		Bool8 m_bMiniGunFireActive;
		Int8 m_nLastWeaponPlaneFrequencyIndex;
		Int8 m_nMiniGunState;
		Int8 m_nChainsawState;
		UInt32 m_nLastFlameThrowerFireTimeMs;
		UInt32 m_nLastSprayCanFireTimeMs;
		UInt32 m_nLastFireExtFireTimeMs;
		UInt32 m_nLastMiniGunFireTimeMs;
		UInt32 m_nLastChainsawEventTimeMs;
		UInt32 m_nLastGunFireTimeMs;
		CAESound *m_pFlameThrowerIdleGasLoopSound;
		*/
		char bPlayedMiniGunFireSound;
		char field_7D;
		char field_7E;
		char field_7F;
		char nChainsawSoundState;
		unsigned int dwFlameThrowerLastPlayedTime;
		unsigned int dwSpraycanLastPlayedTime;
		unsigned int dwExtinguisherLastPlayedTime;
		unsigned int dwMiniGunFireSoundPlayedTime;
		unsigned int dwTimeChainsaw;
		unsigned int dwTimeLastFired;
		CAESound *pSounds;
	} CAEWeaponAudioEntity__Base;

	// CAEPedWeaponAudioEntity
	typedef struct CAEWeaponAudioEntity : CAEWeaponAudioEntity__Base
	{
		/*
		ORIGINAL GTA STRUCT:
		Bool8 m_bInitialised;
  	CPed *m_pParentPed;
		*/
		char bActive;
		CPed* pPed;
	} CAEWeaponAudioEntity;
]]

--shared.validate_size('CAEWeaponAudioEntity', 0xA8)
