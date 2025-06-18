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
shared.require 'CStoredCollPoly'
shared.require 'CPhysical'
shared.require 'CAEPedAudioEntity'
shared.require 'CAEPedSpeechAudioEntity'
shared.require 'CAEWeaponAudioEntity'
shared.require 'CPedIntelligence'
shared.require 'CPlayerData'
shared.require 'AnimBlendFrameData'
shared.require 'CPedAcquaintance'
shared.require 'CPedIK'
shared.require 'ePedState'
shared.require 'CEntity'
shared.require 'CVehicle'
shared.require 'CWeapon'
shared.require 'eWeaponType'
shared.require 'CObject'
shared.require 'CFire'
shared.require 'vector2d'
shared.require 'vector3d'

shared.ffi.cdef[[
	typedef struct CVehicle CVehicle;

	typedef struct CPed : CPhysical
	{
		CAEPedAudioEntity					pedAudio;
		CAEPedSpeechAudioEntity		pedSpeech;
		CAEWeaponAudioEntity			weaponAudio;
		CPedIntelligence         *pIntelligence;
		CPlayerData              *pPlayerData;
		unsigned char             nCreatedBy;
		ePedState                 nPedState;
		int                       nMoveState;
		CStoredCollPoly           storedCollPoly;
		float                     distTravelledSinceLastHeightCheck;
		struct
		{
			unsigned int bIsStanding : 1;
			unsigned int bWasStanding : 1;
			unsigned int bIsLooking : 1;
			unsigned int bIsRestoringLook : 1;
			unsigned int bIsAimingGun : 1;
			unsigned int bIsRestoringGun : 1;
			unsigned int bCanPointGunAtTarget : 1;
			unsigned int bIsTalking : 1;

			unsigned int bInVehicle : 1;
			unsigned int bIsInTheAir : 1;
			unsigned int bIsLanding : 1;
			unsigned int bHitSomethingLastFrame : 1;
			unsigned int bIsNearCar : 1;
			unsigned int bRenderPedInCar : 1;
			unsigned int bUpdateAnimHeading : 1;
			unsigned int bRemoveHead : 1;

			unsigned int bFiringWeapon : 1;
			unsigned int bHasACamera : 1;
			unsigned int bPedIsBleeding : 1;
			unsigned int bStopAndShoot : 1;
			unsigned int bIsPedDieAnimPlaying : 1;
			unsigned int bStayInSamePlace : 1;
			unsigned int bKindaStayInSamePlace : 1;
			unsigned int bBeingChasedByPolice : 1;

			unsigned int bNotAllowedToDuck : 1;
			unsigned int bCrouchWhenShooting : 1;
			unsigned int bIsDucking : 1;
			unsigned int bGetUpAnimStarted : 1;
			unsigned int bDoBloodyFootprints : 1;
			unsigned int bDontDragMeOutCar : 1;
			unsigned int bStillOnValidPoly : 1;
			unsigned int bAllowMedicsToReviveMe : 1;

			unsigned int bResetWalkAnims : 1;
			unsigned int bOnBoat : 1;
			unsigned int bBusJacked : 1;
			unsigned int bFadeOut : 1;
			unsigned int bKnockedUpIntoAir : 1;
			unsigned int bHitSteepSlope : 1;
			unsigned int bCullExtraFarAway : 1;
			unsigned int bTryingToReachDryLand : 1;

			unsigned int bCollidedWithMyVehicle : 1;
			unsigned int bRichFromMugging : 1;
			unsigned int bChrisCriminal : 1;
			unsigned int bShakeFist : 1;
			unsigned int bNoCriticalHits : 1;
			unsigned int bHasAlreadyBeenRecorded : 1;
			unsigned int bUpdateMatricesRequired : 1;
			unsigned int bFleeWhenStanding : 1; //

			unsigned int bMiamiViceCop : 1;  //
			unsigned int bMoneyHasBeenGivenByScript : 1; //
			unsigned int bHasBeenPhotographed : 1;  //
			unsigned int bIsDrowning : 1;
			unsigned int bDrownsInWater : 1;
			unsigned int bHeadStuckInCollision : 1;
			unsigned int bDeadPedInFrontOfCar : 1;
			unsigned int bStayInCarOnJack : 1;

			unsigned int bDontFight : 1;
			unsigned int bDoomAim : 1;
			unsigned int bCanBeShotInVehicle : 1;
			unsigned int bPushedAlongByCar : 1;
			unsigned int bNeverEverTargetThisPed : 1;
			unsigned int bThisPedIsATargetPriority : 1;
			unsigned int bCrouchWhenScared : 1;
			unsigned int bKnockedOffBike : 1;

			unsigned int bDonePositionOutOfCollision : 1;
			unsigned int bDontRender : 1;
			unsigned int bHasBeenAddedToPopulation : 1;
			unsigned int bHasJustLeftCar : 1;
			unsigned int bIsInDisguise : 1;
			unsigned int bDoesntListenToPlayerGroupCommands : 1;
			unsigned int bIsBeingArrested : 1;
			unsigned int bHasJustSoughtCover : 1;

			unsigned int bKilledByStealth : 1;
			unsigned int bDoesntDropWeaponsWhenDead : 1;
			unsigned int bCalledPreRender : 1;
			unsigned int bBloodPuddleCreated : 1;
			unsigned int bPartOfAttackWave : 1;
			unsigned int bClearRadarBlipOnDeath : 1;
			unsigned int bNeverLeavesGroup : 1;
			unsigned int bTestForBlockedPositions : 1;

			unsigned int bRightArmBlocked : 1;
			unsigned int bLeftArmBlocked : 1;
			unsigned int bDuckRightArmBlocked : 1;
			unsigned int bMidriffBlockedForJump : 1;
			unsigned int bFallenDown : 1;
			unsigned int bUseAttractorInstantly : 1;
			unsigned int bDontAcceptIKLookAts : 1;
			unsigned int bHasAScriptBrain : 1;

			unsigned int bWaitingForScriptBrainToLoad : 1;
			unsigned int bHasGroupDriveTask : 1;
			unsigned int bCanExitCar : 1;
			unsigned int CantBeKnockedOffBike : 2;
			unsigned int bHasBeenRendered : 1;
			unsigned int bIsCached : 1;
			unsigned int bPushOtherPeds : 1;

			unsigned int bHasBulletProofVest : 1;
			unsigned int bUsingMobilePhone : 1;
			unsigned int bUpperBodyDamageAnimsOnly : 1;
			unsigned int bStuckUnderCar : 1;
			unsigned int bKeepTasksAfterCleanUp : 1;
			unsigned int bIsDyingStuck : 1;
			unsigned int bIgnoreHeightCheckOnGotoPointTask : 1;
			unsigned int bForceDieInCar : 1;

			unsigned int bCheckColAboveHead : 1;
			unsigned int bIgnoreWeaponRange : 1;
			unsigned int bDruggedUp : 1;
			unsigned int bWantedByPolice : 1;
			unsigned int bSignalAfterKill : 1;
			unsigned int bCanClimbOntoBoat : 1;
			unsigned int bPedHitWallLastFrame : 1;
			unsigned int bIgnoreHeightDifferenceFollowingNodes : 1;

			unsigned int bMoveAnimSpeedHasBeenSetByTask : 1;
			unsigned int bGetOutUpsideDownCar : 1;
			unsigned int bJustGotOffTrain : 1;
			unsigned int bDeathPickupsPersist : 1;
			unsigned int bTestForShotInVehicle : 1;
			unsigned int bUsedForReplay : 1;
		} nPedFlags;
		AnimBlendFrameData *apBones[19];
		unsigned int        nAnimGroup;
		vector2d            vecAnimMovingShiftLocal;
		CPedAcquaintance    acquaintance;
		RpClump            *pWeaponObject;
		RwFrame            *pGunflashObject;
		RpClump            *pGogglesObject;
		unsigned char      *pGogglesState;
		short               nWeaponGunflashAlphaMP1;
		short field_506; // m_nGunFlashBlendOutRate
		short               nWeaponGunflashAlphaMP2;
		short field_50A; // m_nGunFlashBlendOutRate2
		CPedIK              pedIK;
		int field_52C; // m_nAntiSpazTimer
		int field_538; // m_eMoveStateAnim
		int field_53C; // m_eStoredMoveState
		float               fHealth;
		float               fMaxHealth;
		float               fArmour;
		int field_54C; // DontUseSmallerRemovalRange
		vector2d           	vecAnimMovingShift;
		float               fCurrentRotation;
		float               fAimingRotation;
		float               fHeadingChangeRate;
	  float field_564; // m_fHeadingChangeRateAccel
		CPhysical *field_568; // m_pGroundPhysical
		vector3d field_56C; // m_vecGroundOffset
		vector3d field_578; // m_vecGroundNormal
		CEntity            *pContactEntity;
		float field_588; // m_fHitHeadHeight
		CVehicle           *pVehicle;
		CVehicle *field_590; // m_pMyAccidentVehicle
		void *field_594; // m_pAccident
		int                 nPedType;
		void               *pStats;
		CWeapon             aWeapons[13];
		eWeaponType         nSavedWeapon;
		eWeaponType         nDelayedWeapon;
		unsigned int        nDelayedWeaponAmmo;
		unsigned char       nActiveWeaponSlot;
		unsigned char       nWeaponShootingRate;
		unsigned char       nWeaponAccuracy;
		CEntity            *pTargetedObject; // m_pEntLockOnTarget
		CEntity            *pEntMagnetizeTarget;

		// vvv m_vecWeaponPrevPos vvv
		float field_720;
		float field_724;
		float field_728;

		char                nWeaponSkill;
		char                nFightingStyle;
		char                nAllowedAttackMoves;
		char field_72F; // BleedingFrames
		CFire              *pFire;
		float field_734; // FireDamageMultiplier
		CEntity *field_738; // m_pEntLookEntity
		float field_73C; // m_fLookHeading
		int                 nWeaponModelId;
		unsigned int field_744; // m_nUnconsciousTimer
		unsigned int field_748; // m_nLookTimer
		unsigned int field_74C; // m_nAttackTimer
		unsigned int        nDeathTime;
		char                nBodypartToRemove;
		short               nMoneyCount;
		float field_758; // m_wobble
		float field_75C; // m_wobbleSpeed
		char                nLastWeaponDamage;
		CEntity            *pLastEntityDamage;
		unsigned int field_768; // LastDamagedTime
		vector3d            vecTurretOffset;
		unsigned short      nTurretPosnMode;
		float               fTurretAngleA;
		float               fTurretAngleB;
		int                 nTurretAmmo;
		void               *pCoverPoint;
		void               *pEnex;
		float               fRemovalDistMultiplier;
		short               nSpecialModelIndex; // StreamedScriptBrainToLoad
		unsigned int        nLastTalkSfx;
	} CPed;
]]

--shared.validate_size('CPed', 0x79C)
