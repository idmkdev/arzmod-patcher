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

shared.ffi.cdef[[
	typedef struct CWeaponEffects
	{
		/*
		ORIGINAL GTA STRUCT:
		bool m_bRender;
		uint32 clearTargetTimer;
		CVector m_vecTargetPos;
		uint8 m_red;
		uint8 m_green;
		uint8 m_blue;
		uint8 m_alpha;
		float m_fScale;
		float m_fRotate;
		float m_fRadius;
		float m_bLockedOn;
		uint8 m_type;
		*/
		bool    			bActive;
		unsigned int  nTimeWhenToDeactivate;
		vector3d 			vPosn;
		unsigned int 	uiColor;
		float   			fSize;
		float 				field_1C;
		float 				field_20;
		float   			fRotation;
		char 					field_28;
	} CWeaponEffects;
]]

--shared.validate_size('CWeaponEffects', 0x2C)
