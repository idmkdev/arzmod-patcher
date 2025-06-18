--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
  Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CColSphere'
shared.require 'CColBox'
shared.require 'CColLine'
shared.require 'CColDisk'
shared.require 'vector3d'
shared.require 'CColTriangle'
shared.require 'CColTrianglePlane'

shared.ffi.cdef[[
	typedef struct CCollisionData
	{
		unsigned short     nNumSpheres;
    unsigned short     nNumBoxes;
    unsigned short     nNumTriangles;
    unsigned char      nNumLines;
    struct
		{
      unsigned char   bUsesDisks : 1;
      unsigned char   bHasModelSections : 1;
      unsigned char   bHasShadow : 1;
    }                  nFlags;
    CColSphere        *pSpheres;
    CColBox           *pBoxes;
    union
		{
      CColLine      *pLines;
      CColDisk      *pDisks;
    };
    vector3d          *pVertices;
    CColTriangle      *pTriangles;
    CColTrianglePlane *pTrianglePlanes;
    unsigned int       nNumShadowTriangles;
    unsigned int       nNumShadowVertices;
    vector3d          *pShadowVertices;
    CColTriangle      *pShadowTriangles;
    int               *pModelSec;
	} CCollisionData;
]]

--shared.validate_size('CCollisionData', 0x30)
