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
shared.require 'CVehicle'
shared.require 'CEntity'

shared.ffi.cdef[[
	typedef struct CNodeAddress
	{
		short wAreaId;
		short wNodeId;
	} CNodeAddress;

	typedef struct CCarPathLinkAddress
	{
		short wCarPathLinkId : 10;
		short wAreaId : 6;
	} CCarPathLinkAddress;

	typedef struct CAutoPilot
	{
		CNodeAddress         currentAddress;
		CNodeAddress         startingRouteNode;
		CNodeAddress field_8; // veryOldNode
		int field_C; // timeToLeaveLink
		unsigned int         nSpeedScaleFactor; // timeToGetToNextLink
		CCarPathLinkAddress  nCurrentPathNodeInfo;
		CCarPathLinkAddress  nNextPathNodeInfo;
		CCarPathLinkAddress  nPreviousPathNodeInfo;
		unsigned int         nTimeToStartMission; // lastTimeNotStuck
		unsigned int         nTimeSwitchedToRealPhysics; // lastTimeMoving
		char field_24; // invertDirVeryOldLink
		char _smthCurr; // invertDirOldLink
		char _smthNext; // invertDirNewLink
		char                 nCurrentLane;
		char                 nNextLane;
		char                 nCarDrivingStyle;
		char                 nCarMission;
		char                 nTempAction;
		unsigned int         nTempActionTime;
		unsigned int _someStartTime; // lastTimeWeStartedTempActReverse
		char field_34; // whatToTryForReserve
		char field_35; // numTimesWantingToChangeNodes
		float field_38; // actualSpeed
		float                fMaxTrafficSpeed;
		char nCruiseSpeed;
		char field_41; // speedFromNodes
		float field_44; // speedMultiplier
		char field_48[1]; // hooverDistFromTarget
		char field_49; // speedCheat
		char field_4A; // aimAheadOfTarget
		unsigned char        nCarCtrlFlags;
		char field_4C; // ^^^ CONTINUATION
		char                 nStraightLineDistance;
		char field_4E; // followCarDistance
		char field_4F; // targetReachedDist
		char field_50; // laneChangeCounter
		char field_51; // framesFloating
		unsigned short field_52[4]; // constrainArea minX/maxX/minY/maxY
		vector3d              vecDestinationCoors;
		CNodeAddress         aPathFindNodesInfo[8];
		unsigned short       nPathFindNodesCount;
		struct CEntity       *pTargetCar; // targetEntity
		struct CEntity       *pCarWeMakingSlowDownFor; // obstructingEntity
		char field_94; // recordingNumber
		char field_95; // diversion
	} CAutoPilot;
]]

--shared.validate_size('CAutoPilot', 0x98)
