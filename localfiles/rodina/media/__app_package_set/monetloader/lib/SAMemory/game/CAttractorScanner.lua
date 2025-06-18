--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'C2dEffect'
shared.require 'CTaskTimer'

shared.ffi.cdef[[
	typedef struct CEntity CEntity;

	typedef struct CAttractorScanner
	{
		/*
		ORIGINAL GTA STRUCT:
		bool m_bActivated;
		CTaskTimer m_timer;
		C2dEffect *m_pPreviousEffect;
		CEntity *m_pPreviousEntity;
		CEntity *m_entities[10];
		C2dEffect *m_effects[10];
		float m_minDistanceSquared[10];
		*/
		char       field_0;
		CTaskTimer field_4;
		C2dEffect *pEffectInUse;
		CEntity   *field_14;
		CEntity   *field_18[10];
		C2dEffect *field_40[10];
		float      field_68[10];
	} CAttractorScanner;
]]

--shared.validate_size('CAttractorScanner', 0x90)
