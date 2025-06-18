--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
]]

local shared = require 'SAMemory.shared'

local ffi = shared.ffi
local cast = ffi.cast

shared.require 'CCam'
shared.require 'CCamera'

ffi.cdef[[
	typedef struct CWeaponEffects CWeaponEffects;
	typedef struct CVehicle CVehicle;
	typedef struct CPool CPool;
	typedef struct CPed CPed;

	bool _ZN6CTimer11m_UserPauseE[1];
	bool _ZN6CTimer11m_CodePauseE[1];

	void* TheCamera[1];

	void* _ZN6CPools25ms_pPtrNodeSingleLinkPoolE[1];
	void* _ZN6CPools25ms_pPtrNodeDoubleLinkPoolE[1];
	void* _ZN6CPools11ms_pPedPoolE[1];
	void* _ZN6CPools15ms_pVehiclePoolE[1];
	void* _ZN6CPools16ms_pBuildingPoolE[1];
	void* _ZN6CPools14ms_pObjectPoolE[1];
	void* _ZN6CPools13ms_pDummyPoolE[1];
	void* _ZN6CPools16ms_pColModelPoolE[1];
	void* _ZN6CPools12ms_pTaskPoolE[1];
	void* _ZN6CPools23ms_pPedIntelligencePoolE[1];

	void* gCrossHair[2];
	void* _ZN12CUserDisplay14CurrentVehicleE[1];
]]

local function PBOOL(x)
	return cast('bool *', x)
end

local function PPOOL(x)
	return cast('CPool **', x)
end

return {
	_ver 								= '2.0.0.0';

	cast 								= cast;
	require 						= shared.require;

	code_pause					= shared.gta._ZN6CTimer11m_CodePauseE;
	user_pause 					= shared.gta._ZN6CTimer11m_UserPauseE;

	nullptr 						= cast('void *', 0x00000000);
	camera 							= cast('CCamera *', shared.gta.TheCamera);

	-- array[2]
	crosshairs 					= cast('CWeaponEffects *', shared.gta.gCrossHair);

	-- TheCamera.aCams[1].pCamTargetEntity
	player_ped 				  = cast('CPed **',
		cast('uintptr_t', shared.gta.TheCamera) + ffi.offsetof('CCamera', 'aCams') + ffi.sizeof('CCam') + ffi.offsetof('CCam', 'pCamTargetEntity'));

	-- actually CCurrentVehicle, but CCurrentVehicle == CVehicle*
	player_vehicle  		= cast('CVehicle **', shared.gta._ZN12CUserDisplay14CurrentVehicleE);

	-- pools (CPool)
	ptrNodeSinglePool   = PPOOL(shared.gta._ZN6CPools25ms_pPtrNodeSingleLinkPoolE);
	ptrNodeDoublePool   = PPOOL(shared.gta._ZN6CPools25ms_pPtrNodeDoubleLinkPoolE);
	ped_pool 						= PPOOL(shared.gta._ZN6CPools11ms_pPedPoolE);
	vehicle_pool 				= PPOOL(shared.gta._ZN6CPools15ms_pVehiclePoolE);
	building_pool 			= PPOOL(shared.gta._ZN6CPools16ms_pBuildingPoolE);
	object_pool 				= PPOOL(shared.gta._ZN6CPools14ms_pObjectPoolE);
	dummy_pool 					= PPOOL(shared.gta._ZN6CPools13ms_pDummyPoolE);
	colModelPool 			 	= PPOOL(shared.gta._ZN6CPools16ms_pColModelPoolE);
	task_pool 					= PPOOL(shared.gta._ZN6CPools12ms_pTaskPoolE);
	pedIntelligencePool = PPOOL(shared.gta._ZN6CPools23ms_pPedIntelligencePoolE);
}