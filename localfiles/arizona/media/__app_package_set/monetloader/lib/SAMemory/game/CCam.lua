--[[
	Project: SA Memory (Available from https://blast.hk/)
	Developers: LUCHARE, FYP

	Special thanks:
		plugin-sdk (https://github.com/DK22Pac/plugin-sdk) for the structures and addresses.

	Copyright (c) 2018 BlastHack.
	Modified by MonetLoader Team for mobile GTA: SA.
]]

local shared = require 'SAMemory.shared'

shared.require 'eCamMode'
shared.require 'CVehicle'
shared.require 'CPed'
shared.require 'vector3d'

shared.ffi.cdef[[
	typedef struct CCam
	{
		bool          bBelowMinDist;
		bool          bBehindPlayerDesired;
		bool          bCamLookingAtVector;
		bool          bCollisionChecksOn;
		bool          bFixingBeta;
		bool          bTheHeightFixerVehicleIsATrain;
		bool          bLookBehindCamWasInFront;
		bool          bLookingBehind;
		bool          bLookingLeft;
		bool          bLookingRight;
		bool          bResetStatics;
		bool          bResetKeyboardStatics;
		bool          bRotating;
		short         nMode;
		unsigned int  nFinishTime;
		unsigned int  nDoCollisionChecksOnFrameNum;
		unsigned int  nDoCollisionCheckEveryNumOfFrames;
		unsigned int  nFrameNumWereAt;
		unsigned int  nDirectionWasLooking;
		float         fSyphonModeTargetZOffSet;
		float         fAlphaSpeedOverOneFrame;
		float         fBetaSpeedOverOneFrame;
		float         fCamBufferedHeight;
		float         fCamBufferedHeightSpeed;
		float         fCloseInPedHeightOffset;
		float         fCloseInPedHeightOffsetSpeed;
		float         fCloseInCarHeightOffset;
		float         fCloseInCarHeightOffsetSpeed;
		float         fDimensionOfHighestNearCar;
		float         fDistanceBeforeChanges;
		float         fFovSpeedOverOneFrame;
		float         fMinDistAwayFromCamWhenInterPolating;
		float         fPedBetweenCameraHeightOffset;
		float         fPlayerInFrontSyphonAngleOffSet;
		float         fRadiusForDead;
		float         fRealGroundDist;
		float         fTimeElapsedFloat;
		float         fTilt;
		float         fTiltSpeed;
		float         fTransitionBeta;
		float         fTrueBeta;
		float         fTrueAlpha;
		float         fInitialPlayerOrientation;
		float         fVerticalAngle;
		float         fAlphaSpeed;
		float         fFOV;
		float         fFOVSpeed;
		float         fHorizontalAngle;
		float         fBetaSpeed;
		float         fDistance;
		float         fDistanceSpeed;
		float         fCaMinDistance;
		float         fCaMaxDistance;
		float         fSpeedVar;
		float         fCameraHeightMultiplier;
		float         fTargetZoomGroundOne;
		float         fTargetZoomGroundTwo;
		float         fTargetZoomGroundThree;
		float         fTargetZoomOneZExtra;
		float         fTargetZoomTwoZExtra;
		float         fTargetZoomTwoInteriorZExtra;
		float         fTargetZoomThreeZExtra;
		float         fTargetZoomZCloseIn;
		float         fMinRealGroundDist;
		float         fTargetCloseInDist;
		float         fBeta_Targeting;
		float         fX_Targetting;
		float         fY_Targetting;
		int           pCarWeAreFocussingOn;
		float         pCarWeAreFocussingOnI;
		float         fCamBumpedHorz;
		float         fCamBumpedVert;
		unsigned int  nCamBumpedTime;
		vector3d       vecSourceSpeedOverOneFrame;
		vector3d       vecTargetSpeedOverOneFrame;
		vector3d       vecUpOverOneFrame;
		vector3d       vecTargetCoorsForFudgeInter;
		vector3d       vecCamFixedModeVector;
		vector3d       vecCamFixedModeSource;
		vector3d       vecCamFixedModeUpOffSet;
		vector3d       vecLastAboveWaterCamPosition;
		vector3d       vecBufferedPlayerBodyOffset;
		vector3d       vecFront;
		vector3d       vecSource;
		vector3d       vecSourceBeforeLookBehind;
		vector3d       vecUp;
		vector3d       avecPreviousVectors[2];
		vector3d       avecTargetHistoryPos[4];
		unsigned int  anTargetHistoryTime[4];
		unsigned int  nCurrentHistoryPoints;
		CEntity      *pCamTargetEntity;
		float         fCameraDistance;
		float         fIdealAlpha;
		float         fPlayerVelocity;
		CVehicle     *pLastCarEntered;
		CPed         *pLastPedLookedAt;
		bool          bFirstPersonRunAboutActive;
	} CCam;
]]

--shared.validate_size('CCam', 0x238)
