--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
  Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'RenderWare'
shared.require 'CVehicle'
shared.require 'CPhysical'
shared.require 'CColPoint'
shared.require 'CEntity'
shared.require 'CRideAnimData'
shared.require 'matrix'
shared.require 'vector3d'

shared.ffi.cdef[[
	typedef enum eBikeNodes
	{
		BIKE_NODE_NONE = 0,
		BIKE_CHASSIS = 1,
		BIKE_FORKS_FRONT = 2,
		BIKE_FORKS_REAR = 3,
		BIKE_WHEEL_FRONT = 4,
		BIKE_WHEEL_REAR = 5,
		BIKE_MUDGUARD = 6,
		BIKE_HANDLEBARS = 7,
		BIKE_MISC_A = 8,
		BIKE_MISC_B = 9,
		BIKE_NUNODES
	} eBikeNodes;

	typedef struct CBike : CVehicle
	{
		RwFrame       	*pBikeNodes[BIKE_NUNODES];
    bool          	bLeanMatrixCalculated;
    matrix        	mLeanMatrix;
    union
		{
			unsigned char nDamageFlags;
			struct
			{
        unsigned char bShouldNotChangeColour : 1;
        unsigned char bPanelsAreThougher : 1;
        unsigned char bWaterTight : 1;
        unsigned char bGettingPickedUp : 1;
        unsigned char bOnSideStand : 1;
        unsigned char bPlayerBoost : 1;
        unsigned char bEngineOnFire : 1;
        unsigned char bWheelieForCamera : 1;
			} damageFlags;
		};
    vector3d        vecAveGroundNormal;
    vector3d        vecGroundRight;
    vector3d 				field_630; // m_vecOldSpeedForPlayback
    void          	*pBikeHandlingData;
    CRideAnimData  	rideAnimData;
    unsigned char  	anWheelDamageState[2];
    CColPoint      	anWheelColPoint[4];
    float 					field_710[4]; // m_aWheelRatios
    float 					field_720[4]; // m_aRatioHistory
    float 					field_730[4]; // m_aWheelCounts
    float 					field_740; // fBrakeCount
    int            	anWheelSurfaceType[2]; // aWheelSkidmarkType
    char 						field_74C[2]; // bWheelBloody
    char 						field_74E[2]; // bMoreSkidMarks
    float          	afWheelRotationX[2];
    float 					fWheelSpeed[2];
    float 					field_760; // m_aWheelSuspensionHeights[0]
    float 					field_764; // m_aWheelSuspensionHeights[1]
    float 					field_768; // m_aWheelOrigHeights[0]
    float 					field_76C; // m_aWheelOrigHeights[1]
    float 					field_770[4]; // m_fSuspensionLength
    float 					field_780[4]; // m_fLineLength
    float          	fHeightAboveRoad;
    float          	fCarTraction;
    float 					field_798; // m_fSwingArmLength
    float 					field_79C; // m_fForkYOffset
    float 					field_7A0; // m_fForkZOffset
    float 					field_7A4; // m_fSteerAngleTan
    unsigned short 	field_7A8; // nBrakesOn
    float 					field_7AC; // m_fTyreTemp
    float 					field_7B0; // m_fBrakingSlide
    bool           	bPedLeftHandFixed;
    bool           	bPedRightHandFixed;
    char 						field_7B6[1]; // m_nTestPedCollision
    float 					field_7B8; // fPrevSpeed
    float 					field_7BC; // m_BlowUpTimer
    CPhysical       *apWheelCollisionEntity[4];
    vector3d        avTouchPointsLocalSpace[4];
    CEntity       	*pDamager;
    unsigned char  	nNumContactWheels;
    unsigned char  	nNumWheelsOnGround;
    unsigned char 	field_806; // m_nDriveWheelsOnGroundLastFrame
    float 					field_808; // m_fGasPedalAudioRevs
    unsigned int   	anWheelState[2];
	} CBike;
]]

--shared.validate_size('CBike', 0x814)
