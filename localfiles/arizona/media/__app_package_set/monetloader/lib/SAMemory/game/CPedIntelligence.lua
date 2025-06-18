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
shared.require 'CPed'
shared.require 'CTaskManager'
shared.require 'CEventHandler'
shared.require 'CEventGroup'
shared.require 'CEventScanner'
shared.require 'CEntityScanner'
shared.require 'CEntity'

shared.ffi.cdef[[
  typedef struct CMentalState
  {
    unsigned char m_iAngerAtPlayer;
    unsigned char m_iLastAngerAtPlayer;
    CTaskTimer m_angerTimer;
    unsigned short m_iHealth;
    unsigned short m_iLastHealth;
    unsigned short m_iCarHealth;
    unsigned short m_iLastCarHealth;
    unsigned char m_bInCarLastTime;
  } CMentalState;

  typedef struct CPedStuckChecker
  {
    vector3d m_vecPreviousPos;
    unsigned short m_nStuckCounter;
    unsigned short m_nStuck;
  } CPedStuckChecker;
  
  
	typedef struct CPedIntelligence
	{
		CPed    			 *pPed;
    CTaskManager   TaskMgr;
    CEventHandler  eventHandler;
    CEventGroup    eventGroup;
    unsigned int   dwDecisionMakerType;
    unsigned int   dwDecisionMakerTypeInGroup;
    float          fHearingRange;
    float          fSeeingRange;
    unsigned int   dwDmNumPedsToScan;
    float          fDmRadius;
    float field_CC; // m_fFollowNodeThresholdDistance
    char field_D0; // m_iNextEventResponseSequence
    unsigned char  nEventId;
    unsigned char  nEventPriority;
    CEntityScanner vehicleScanner;
    CEntityScanner pedScanner;
    CMentalState   mentalState;
    CEventScanner  eventScanner;
    char field_260; // CCollisionEventScanner::m_bAlreadyHitByCar
    CPedStuckChecker stuckChecker;
    int field_274; // m_iStaticCounter
    unsigned int field_278; // m_iNumFramesWithoutCollision
    vector3d m_vPedPositionAtFirstCollision;
    CEntity *apInterestingEntities[3];
	} CPedIntelligence;
]]

--shared.validate_size('CPedIntelligence', 0x294)
