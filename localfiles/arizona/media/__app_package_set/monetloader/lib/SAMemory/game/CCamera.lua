--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
  Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'matrix'
shared.require 'CEntity'
shared.require 'CPlaceable'
shared.require 'CCam'
shared.require 'CCamPathSplines'
shared.require 'CQueuedMode'
shared.require 'vector3d'

shared.ffi.cdef[[
  typedef struct CVehicleCamTweak
  {
    int m_ModelId;
    float m_LenMod;
    float m_TargetZMod;
    float m_PitchMod;
  } CVehicleCamTweak;

	typedef struct CCamera : CPlaceable
	{
		bool             bAboveGroundTrainNodesLoaded;
    bool             bBelowGroundTrainNodesLoaded;
    bool             bCamDirectlyBehind;
    bool             bCamDirectlyInFront;
    bool             bCameraJustRestored;
    bool             bcutsceneFinished;
    bool             bCullZoneChecksOn;
    bool             bIdleOn;
    bool             bInATunnelAndABigVehicle;
    bool             bInitialNodeFound;
    bool             bInitialNoNodeStaticsSet;
    bool             bIgnoreFadingStuffForMusic;
    bool             bPlayerIsInGarage;
    bool             bPlayerWasOnBike;
    bool             bJustCameOutOfGarage;
    bool             bJustInitalised;
    bool             bJust_Switched;
    bool             bLookingAtPlayer;
    bool             bLookingAtVector;
    bool             bMoveCamToAvoidGeom;
    bool             bObbeCinematicPedCamOn;
    bool             bObbeCinematicCarCamOn;
    bool             bRestoreByJumpCut;
    bool             bUseNearClipScript;
    bool             bStartInterScript;
    bool             bStartingSpline;
    bool             bTargetJustBeenOnTrain;
    bool             bTargetJustCameOffTrain;
    bool             bUseSpecialFovTrain;
    bool             bUseTransitionBeta;
    bool             bUseScriptZoomValuePed;
    bool             bUseScriptZoomValueCar;
    bool             bWaitForInterpolToFinish;
    bool             bItsOkToLookJustAtThePlayer;
    bool             bWantsToSwitchWidescreenOff;
    bool             bWideScreenOn;
    bool             b1rstPersonRunCloseToAWall;
    bool             bHeadBob;
    bool             bVehicleSuspenHigh;
    bool             bEnable1rstPersonCamCntrlsScript;
    bool             bAllow1rstPersonWeaponsCamera;
    bool             bCooperativeCamMode;
    bool             bAllowShootingWith2PlayersInCar;
    bool             bDisableFirstPersonInCar;
    unsigned short   nModeForTwoPlayersSeparateCars;
    unsigned short   nModeForTwoPlayersSameCarShootingAllowed;
    unsigned short   nModeForTwoPlayersSameCarShootingNotAllowed;
    unsigned short   nModeForTwoPlayersNotBothInCar;
    bool             bGarageFixedCamPositionSet;
    bool             bDoingSpecialInterPolation;
    bool             bScriptParametersSetForInterPol;
    bool             bFading;
    bool             bMusicFading;
    bool             bMusicFadedOut;
    bool             bFailedCullZoneTestPreviously;
    bool             bFadeTargetIsSplashScreen;
    bool             bWorldViewerBeingUsed;
    bool             bTransitionJUSTStarted;
    bool             bTransitionState;
    bool             nActiveCam;

    unsigned int     nCamShakeStart;
    unsigned int     nFirstPersonCamLastInputTime;
    unsigned int     nLongestTimeInMill;
    unsigned int     nNumberOfTrainCamNodes;
    unsigned int     nTimeLastChange;
    unsigned int     nTimeWeLeftIdle_StillNoInput;
    unsigned int     nTimeWeEnteredIdle;
    unsigned int     nTimeTransitionStart;
    unsigned int     nTransitionDuration;
    unsigned int     nTransitionDurationTargetCoors;
    unsigned int     nBlurBlue;
    unsigned int     nBlurGreen;
    unsigned int     nBlurRed;
    unsigned int     nBlurType;
    unsigned int     nWorkOutSpeedThisNumFrames;
    unsigned int     nNumFramesSoFar;
    unsigned int     nCurrentTrainCamNode;
    unsigned int     nMotionBlur;
    unsigned int     nMotionBlurAddAlpha;
    unsigned int     nCheckCullZoneThisNumFrames;
    unsigned int     nZoneCullFrameNumWereAt;
    unsigned int     nWhoIsInControlOfTheCamera;
    unsigned int     nCarZoom;
    float            fCarZoomBase;
    float            fCarZoomTotal;
    float            fCarZoomSmoothed;
    float            fCarZoomValueScript;
    unsigned int     fPedZoom; // fix
    float            fPedZoomBase;
    float            fPedZoomTotal;
    float            fPedZoomSmoothed;
    float            fPedZoomValueScript;
    float            fCamFrontXNorm;
    float            fCamFrontYNorm;
    float            fDistanceToWater;
    float            fHeightOfNearestWater;
    float            fFOVDuringInter;
    float            fLODDistMultiplier;
    float            fGenerationDistMultiplier;
    float            fAlphaSpeedAtStartInter;
    float            fAlphaWhenInterPol;
    float            fAlphaDuringInterPol;
    float            fBetaDuringInterPol;
    float            fBetaSpeedAtStartInter;
    float            fBetaWhenInterPol;
    float            fFOVWhenInterPol;
    float            fFOVSpeedAtStartInter;
    float            fStartingBetaForInterPol;
    float            fStartingAlphaForInterPol;
    float            fPedOrientForBehindOrInFront;
    float            fCameraAverageSpeed;
    float            fCameraSpeedSoFar;
    float            fCamShakeForce;
    float            fFovForTrain;
    float            fFOV_Wide_Screen;
    float            fNearClipScript;
    float            fOldBetaDiff;
    float            fPositionAlongSpline;
    float            fScreenReductionPercentage;
    float            fScreenReductionSpeed;
    float            fAlphaForPlayerAnim1rstPerson;
    float            fOrientation;
    float            fPlayerExhaustion;
    float            fSoundDistUp;
    float            fSoundDistUpAsRead;
    float            fSoundDistUpAsReadOld;
    float            fAvoidTheGeometryProbsTimer;
    unsigned short   nAvoidTheGeometryProbsDirn;

    float            fWideScreenReductionAmount;
    float            fStartingFOVForInterPol;
    CCam             aCams[3];
    void					   *pToGarageWeAreIn;
    void					   *pToGarageWeAreInForHackAvoidFirstPerson;
    CQueuedMode      PlayerMode;
    CQueuedMode      PlayerWeaponMode;
    vector3d          vecPreviousCameraPosition;
    vector3d          vecRealPreviousCameraPosition;
    vector3d          vecAimingTargetCoors;
    vector3d          vecFixedModeVector;
    vector3d          vecFixedModeSource;
    vector3d          vecFixedModeUpOffSet;
    vector3d          vecCutSceneOffset;
    vector3d          vecStartingSourceForInterPol;
    vector3d          vecStartingTargetForInterPol;
    vector3d          vecStartingUpForInterPol;
    vector3d          vecSourceSpeedAtStartInter;
    vector3d          vecTargetSpeedAtStartInter;
    vector3d          vecUpSpeedAtStartInter;
    vector3d          vecSourceWhenInterPol;
    vector3d          vecTargetWhenInterPol;
    vector3d          vecUpWhenInterPol;
    vector3d          vecClearGeometryVec;
    vector3d          vecGameCamPos;
    vector3d          vecSourceDuringInter;
    vector3d          vecTargetDuringInter;
    vector3d          vecUpDuringInter;
    vector3d          vecAttachedCamOffset;
    vector3d          vecAttachedCamLookAt;
    float            fAttachedCamAngle;
    RwCamera        *pRwCamera;
    CEntity   			*pTargetEntity;
    CEntity   			*pAttachedEntity;
    CCamPathSplines  aPathArray[4];
    bool             bMirrorActive;
    bool             bResetOldMatrix;

    float m_sphereMapRadius; // new

    matrix          	mCameraMatrix;
    matrix          	mCameraMatrixOld;
    matrix          	mViewMatrix;
    matrix          	mMatInverse;
    matrix          	mMatMirrorInverse;
    matrix          	mMatMirror;
    vector3d          avecFrustumNormals[4];
    vector3d field_B54[4]; // frustrum world normals
    vector3d field_B84[4]; // frustrum world normals mirror
    float field_BB4[4]; // frustrum plane offsets
    float field_BC4[4]; // frustrum plane offsets mirror
    vector3d field_BD4; // old source for inter
    vector3d vecOldFrontForInter;
    vector3d vecOldUpForInter;
    float field_BF8; // old fov for inter
    float            fFadeAlpha;
    float field_C00; // floating fade music
    float            fFadeDuration;
    float m_fTimeToFadeMusic;
    float m_fTimeToWaitToFadeMusic;
    float m_fFractionInterToStopMoving;
    float m_fFractionInterToStopCatchUp;
    float m_fFractionInterToStopMovingTarget;
    float m_fFractionInterToStopCatchUpTarget;
    float m_fGaitSwayBuffer;
    float m_fScriptPercentageInterToStopMoving;
    float m_fScriptPercentageInterToCatchUp;
    unsigned int m_fScriptTimeForInterPolation;
    unsigned short   nFadeInOutFlag; // fading direction
    int m_iModeObbeCamIsInForCar;
    unsigned short m_iModeToGoTo;
    unsigned short m_iMusicFadingDirection;
    unsigned short m_iTypeOfSwitch;
    unsigned int     nFadeStartTime;
    unsigned int field_C44; // fade time started music
    int field_C48; // num extra entitys to ignore
    CEntity* field_C4C; // entity 1
    CEntity* field_C50; // entity 2
    float field_C54; // duck z mod
    float field_C58; // duck z mod aim
    float            nTransverseStartTime;
    float            nTransverseEndTime;
    vector3d          vecTransverseEndPoint;
    vector3d          vecTransverseStartPoint;
    unsigned char    nTransverseMode; // track smooth ends
    vector3d field_C80; // vector track script
    char field_C8C; // bool vector track script
    float field_C90; // degree handshake
    float            nStartJiggleTime;
    float            nEndJiggleTime;
    bool field_C9C; // shake script
    int field_CA0; // cur shake cam
    float            nStartZoomTime;
    float            nEndZoomTime;
    float            fZoomInFactor;
    float            fZoomOutFactor;
    unsigned char    nZoomMode; // lerp smooth ends
    char field_CB5; // bool fov script
    float field_CB8; // my fov
    float field_CBC; // vector move start time
    float field_CC0; // vector move end time
    vector3d field_CC4; // vector move from
    vector3d field_CD0; // vector move to
    char field_CDC; // vector move smooth ends
    vector3d field_CE0; // vector move script
    char field_CEC; // bool vector move script
    bool bBlockZoom; // persist fov
    char field_CEE; // persist cam pos
    char field_CEF; // persist cam look at
    char field_CF0; // force cinema cam
    CVehicleCamTweak field_CF4[5]; // vehicle tweaks
    bool m_bInitedVehicleCamTweaks;
    float m_VehicleTweakLenMod;
    float m_VehicleTweakTargetZMod;
    float m_VehicleTweakPitchMod;
    int m_VehicleTweakLastModelId;
    float m_TimeStartFOVLO;
    float m_TimeEndFOVLO;
    float m_FOVStartFOVLO;
    vector3d m_StartPositionFOVLO;
    float m_FOVTargetFOVLO;
    bool m_bSmoothLerpFOVLO;
    bool m_bInitLockOnCam;
	} CCamera;
]]

--shared.validate_size('CCamera', 0xD78)
