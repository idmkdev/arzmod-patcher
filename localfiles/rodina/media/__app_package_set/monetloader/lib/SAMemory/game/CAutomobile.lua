--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
  Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'CDamageManager'
shared.require 'CEntity'
shared.require 'CDoor'
shared.require 'CBouncingPanel'
shared.require 'CColPoint'
shared.require 'CVehicle'
shared.require 'vector3d'

shared.ffi.cdef[[
	typedef enum eCarNodes
	{
		CAR_NODE_NONE = 0,
		CAR_CHASSIS = 1,
		CAR_WHEEL_RF = 2,
		CAR_WHEEL_RM = 3,
		CAR_WHEEL_RB = 4,
		CAR_WHEEL_LF = 5,
		CAR_WHEEL_LM = 6,
		CAR_WHEEL_LB = 7,
		CAR_DOOR_RF = 8,
		CAR_DOOR_RR = 9,
		CAR_DOOR_LF = 10,
		CAR_DOOR_LR = 11,
		CAR_BUMP_FRONT = 12,
		CAR_BUMP_REAR = 13,
		CAR_WING_RF = 14,
		CAR_WING_LF = 15,
		CAR_BONNET = 16,
		CAR_BOOT = 17,
		CAR_WINDSCREEN = 18,
		CAR_EXHAUST = 19,
		CAR_MISC_A = 20,
		CAR_MISC_B = 21,
		CAR_MISC_C = 22,
		CAR_MISC_D = 23,
		CAR_MISC_E = 24,
		CAR_NUNODES
	} eCarNodes;

	typedef struct CAutomobile : CVehicle
	{
		CDamageManager 		damageManager;
    CDoor 						doors[6];
    RwFrame 					*pCarNodes[CAR_NUNODES];
    CBouncingPanel 		panels[3];
    CDoor 						swingingChassis;
    CColPoint 				wheelColPoint[4];
    float 						wheelsDistancesToGround1[4];
    float 						wheelsDistancesToGround2[4];
    float 						field_7F4[4]; // m_aWheelCounts
    float 						field_800; // fBrakeCount
    float 						field_804; // m_fEngineRevs
    float 						field_80C; // m_fEngineForce
    int 							field_810[4]; // aWheelSkidmarkType
    char 							field_81C[4]; // bWheelBloody
    bool							bMoreSkidMarks[4];
    float 						fWheelRotation[4];
    float 						field_838[4]; // m_aWheelSuspensionHeights
    float 						fWheelSpeed[4];
    int 							field_858[4]; // m_aWheelLongitudinalSlip

    unsigned char 		taxiAvaliable : 1;
    unsigned char 		shouldNotChangeColour : 1;
    unsigned char     waterTight : 1;
    unsigned char     doesNotGetDamagedUpsideDown : 1;
    unsigned char     canBeVisiblyDamaged : 1;
    unsigned char     tankExplodesCars : 1;
    unsigned char     isBoggedDownInSand : 1;
    unsigned char     isMonsterTruck : 1;

    unsigned short    nBrakesOn;
    unsigned short 		wMiscComponentAngle;
    unsigned short 		wVoodooSuspension;
    int 							dwBusDoorTimerEnd;
    int 							dwBusDoorTimerStart;
    float 						wheelOffsetZ[4];
    float 						lineLength[4];
    float 						fFrontHeightAboveRoad;
    float 						fRearHeightAboveRoad;
    float	 						fCarTraction;
    float 						fNitroValue;
    float 						field_8A4; // ZRot
    float 						fRotationBalance; // ZRotSpeed
    float							fMoveDirection; // fPrevSpeed
    vector3d          vecOldMoveSpeed;
    vector3d          vecOldTurnSpeed;
    float 						field_8C8[6]; // DoorRotation
    float 						dwBurnTimer;
    CEntity 					*pWheelCollisionEntity[4];
    vector3d 					vWheelCollisionPos[4];
    CEntity           *pEntityThatSetUsOnFire;
    float             fTransformPosition;
    short             nTransformState;
    float             fBasePositions[4];
    float             fLeftDoorOpenForDriveBys;
    float             fRightDoorOpenForDriveBys;
    float 						fDoomVerticalRotation;
    float 						fDoomHorizontalRotation;
    float 						fForcedOrientation;
    float 						fUpDownLightAngle[2]; // PropRotate / CumulativeDamage
    unsigned char 		nNumContactWheels;
    unsigned char 		nWheelsOnGround;
    unsigned char 		field_962; // m_nDriveWheelsOnGroundLastFrame
    float 						field_964; // m_fGasPedalAudioRevs
    int 							field_968[4]; // m_aWheelState
    void 							*pNitroParticle[2];
    char 							field_980; // m_HarvesterTimer
    char 							field_981; // m_statusWhenEngineBlown
    float 						field_984; // m_heliDustRatio
	} CAutomobile;
]]

--shared.validate_size('CAutomobile', 0x988)
