--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

require 'SAMemory.game.vector3d'
require 'SAMemory.game.RenderWare'

local shared = require 'SAMemory.shared'
local mt = require 'SAMemory.metatype'
local ffi = require 'ffi'

ffi.cdef[[
	typedef struct matrix3x3
	{
		vector3d      right;
		unsigned int 	flags;
		vector3d      up;
		unsigned int 	pad1;
		vector3d      at;
		unsigned int 	pad2;
		vector3d      pos;
		unsigned int 	pad3;
		RwMatrix 			*pAttachMatrix;
		bool 					bOwnsAttachedMatrix;
	} matrix;

	void _ZN7CMatrix6AttachEP11RwMatrixTagb(void* thiz, RwMatrix* pRwMat, bool owner);
	void _ZN7CMatrix6DetachEv(void* thiz);
	void _ZN7CMatrix6UpdateEv(void* thiz);
	void _ZNK7CMatrix8UpdateRWEv(void* thiz);
	void _ZN7CMatrix16ResetOrientationEv(void* thiz);
	void _ZN7CMatrix14SetRotateXOnlyEf(void* thiz, float a);
	void _ZN7CMatrix14SetRotateYOnlyEf(void* thiz, float a);
	void _ZN7CMatrix14SetRotateZOnlyEf(void* thiz, float a);
	void _ZN7CMatrix10SetRotateXEf(void* thiz, float a);
	void _ZN7CMatrix10SetRotateYEf(void* thiz, float a);
	void _ZN7CMatrix10SetRotateZEf(void* thiz, float a);
	void _ZN7CMatrix9SetRotateEfff(void* thiz, float x, float y, float z);
	void _ZN7CMatrix7RotateXEf(void* thiz, float a);
	void _ZN7CMatrix7RotateYEf(void* thiz, float a);
	void _ZN7CMatrix7RotateZEf(void* thiz, float a);
	void _ZN7CMatrix6RotateEfff(void* thiz, float x, float y, float z);
]]

local matrix = {
	Attach 									= shared.gta._ZN7CMatrix6AttachEP11RwMatrixTagb,
	Detach 									= shared.gta._ZN7CMatrix6DetachEv,
	Update 									= shared.gta._ZN7CMatrix6UpdateEv,
	UpdateRWWithAttached 		= shared.gta._ZNK7CMatrix8UpdateRWEv,
	ResetOrientation 				= shared.gta._ZN7CMatrix16ResetOrientationEv,
	SetRotateXOnly 					= shared.gta._ZN7CMatrix14SetRotateXOnlyEf,
	SetRotateYOnly 					= shared.gta._ZN7CMatrix14SetRotateYOnlyEf,
	SetRotateZOnly 					= shared.gta._ZN7CMatrix14SetRotateZOnlyEf,
	SetRotateX 							= shared.gta._ZN7CMatrix10SetRotateXEf,
	SetRotateY 							= shared.gta._ZN7CMatrix10SetRotateYEf,
	SetRotateZ 							= shared.gta._ZN7CMatrix10SetRotateZEf,
	SetRotate 							= shared.gta._ZN7CMatrix9SetRotateEfff,
	RotateX 								= shared.gta._ZN7CMatrix7RotateXEf,
	RotateY 								= shared.gta._ZN7CMatrix7RotateYEf,
	RotateZ 								= shared.gta._ZN7CMatrix7RotateZEf,
	Rotate 									= shared.gta._ZN7CMatrix6RotateEfff
}

mt.provide_access('matrix', matrix, true, false)
