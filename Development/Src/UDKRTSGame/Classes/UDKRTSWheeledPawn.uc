//=============================================================================
// UDKRTSWheeledPawn: Base class used for all vehicles.
//
// Pawn's were used to simplify vehicles, as physics vehicles simply used more
// resources on the mobile platform. For game play reasons, it was not 
// desirable to have vehicles be able to flip over and so forth.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSWheeledPawn extends UDKRTSPawn;

// Left front wheel
var(WheeledPawn) const Name LeftFrontWheelSkelControlName;
// Left rear wheels
var(WheeledPawn) const Name LeftRearWheelSkelControlName;
// Right front wheel
var(WheeledPawn) const Name RightFrontWheelSkelControlName;
// Right rear wheel
var(WheeledPawn) const Name RightRearWheelSkelControlName;
// Turret control
var(WheeledPawn) const Name TurretLookAtSkelControlName;
// Turret socket name
var(WheeledPawn) const Name TurretSocketName;
// Explosion sound
var(WheeledPawn) const SoundCue ExplosionSoundCue;
// Explosion particle effect
var(WheeledPawn) const ParticleSystem ExplosionParticleTemplate;
// Ambient engine sound audio component
var(WheeledPawn) const AudioComponent EngineAmbientSound;
// Starting engine sound
var(WheeledPawn) const SoundCue EngineStartUpSoundCue;
// Wheel rotation speed
var(WheeledPawn) const float WheelRotationSpeed;
// Maximum wheel turn
var(WheeledPawn) const float MaxWheelTurn;

// Left front wheel skeletal control
var PrivateWrite SkelControlSingleBone LeftFrontWheelSkelControl;
// Left rear wheel skeletal control
var PrivateWrite SkelControlSingleBone LeftRearWheelSkelControl;
// Right front wheel skeletal control
var PrivateWrite SkelControlSingleBone RightFrontWheelSkelControl;
// Right rear wheel skeletal control
var PrivateWrite SkelControlSingleBone RightRearWheelSkelControl;
// Turret look at skel control
var PrivateWrite SkelControlLookAt TurretLookAtSkelControl;
// Previous yaw of the vehicle, used for tracking if the wheels need to turn or not
var Private int PreviousYaw;

/**
 * Called when the actor is spawned into the world
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// Play the engine start up sound
	if (EngineStartUpSoundCue != None)
	{
		PlaySound(EngineStartUpSoundCue);
	}

	// Fade the ambient engine sound in
	if (EngineAmbientSound != None)
	{
		EngineAmbientSound.FadeIn(1.f, 1.f);
	}
}

/**
 * Called when a skeletal mesh component has initialized its anim tree instance.
 *
 * @param		SkelComp		Skeletal mesh component that initialized its anim tree instance.
 */
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	if (SkelComp == Mesh)
	{
		LeftFrontWheelSkelControl = SkelControlSingleBone(Mesh.FindSkelControl(LeftFrontWheelSkelControlName));
		LeftRearWheelSkelControl = SkelControlSingleBone(Mesh.FindSkelControl(LeftRearWheelSkelControlName));
		RightFrontWheelSkelControl = SkelControlSingleBone(Mesh.FindSkelControl(RightFrontWheelSkelControlName));
		RightRearWheelSkelControl = SkelControlSingleBone(Mesh.FindSkelControl(RightRearWheelSkelControlName));
		TurretLookAtSkelControl = SkelControlLookAt(Mesh.FindSkelControl(TurretLookAtSkelControlName));
	}
}

/**
 * Called when the actor is about to be removed from the world
 */
simulated event Destroyed()
{
	Super.Destroyed();

	// Null object references so that garbage collection can occur safely
	LeftFrontWheelSkelControl = None;
	LeftRearWheelSkelControl = None;
	RightFrontWheelSkelControl = None;
	RightRearWheelSkelControl = None;
	TurretLookAtSkelControl = None;
}

/**
 * Called when the actor is updated
 *
 * @param		DeltaTime		Time since the last updated
 */
simulated function Tick(float DeltaTime)
{
	local float Speed, SpeedPercentage, CurrentWheelRotation, DesiredWheelTurn;
	local int DeltaYaw;
	local UDKRTSAIController UDKRTSAIController;

	Super.Tick(DeltaTime);

	Speed = VSize(Velocity);
	SpeedPercentage = (GroundSpeed <= 0.f) ? 0.f : Speed / GroundSpeed;	

	// Check if we need to increase the pitch of the sound
	if (EngineAmbientSound != None)
	{
		EngineAmbientSound.SetFloatParameter('Pitch', SpeedPercentage);
	}

	// Update wheel states
	if (LeftFrontWheelSkelControl != None && LeftRearWheelSkelControl != None && RightFrontWheelSkelControl != None && RightRearWheelSkelControl != None)
	{
		CurrentWheelRotation = WheelRotationSpeed * DeltaTime * SpeedPercentage;

		// Rotate wheels based on the speed of the vehicle
		if (Speed > 0.f)
		{
			LeftFrontWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
			LeftRearWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
			RightFrontWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
			RightRearWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
		}
		else if (Speed < 0.f)
		{
			LeftFrontWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;
			LeftRearWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;
			RightFrontWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;
			RightRearWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;
		}

		UDKRTSAIController = UDKRTSAIController(Controller);
		if (UDKRTSAIController != None)
		{
			// Check if we need to rotate the wheels to simulate the vehicle turning
			if (NeedsToTurnWithPrecision(UDKRTSAIController.GetDestinationPosition(), MustFaceDirectionBeforeMovingPrecision - 0.05f))
			{
				CurrentWheelRotation = WheelRotationSpeed * DeltaTime * 0.125f;
				DeltaYaw = Rotation.Yaw - PreviousYaw;

				if (DeltaYaw < 0)
				{
					DesiredWheelTurn = -MaxWheelTurn;
					LeftFrontWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;
					LeftRearWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;
					RightFrontWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
					RightRearWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
				}
				else if (DeltaYaw > 0)
				{
					DesiredWheelTurn = MaxWheelTurn;
					LeftFrontWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
					LeftRearWheelSkelControl.BoneRotation.Pitch -= CurrentWheelRotation;
					RightFrontWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;
					RightRearWheelSkelControl.BoneRotation.Pitch += CurrentWheelRotation;

				}
				else
				{
					DesiredWheelTurn = 0.f;
				}
			}
			else
			{
				DesiredWheelTurn = 0.f;
			}

			// Smoothly interpolate the rotation of the wheels
			LeftFrontWheelSkelControl.BoneRotation.Yaw = Lerp(LeftFrontWheelSkelControl.BoneRotation.Yaw, DesiredWheelTurn, FMin(6.f * DeltaTime, 0.99f));
			RightFrontWheelSkelControl.BoneRotation.Yaw = Lerp(LeftFrontWheelSkelControl.BoneRotation.Yaw, DesiredWheelTurn, FMin(6.f * DeltaTime, 0.99f));

			LeftRearWheelSkelControl.BoneRotation.Yaw = Lerp(LeftRearWheelSkelControl.BoneRotation.Yaw, -DesiredWheelTurn, FMin(6.f * DeltaTime, 0.99f));
			RightRearWheelSkelControl.BoneRotation.Yaw = Lerp(RightRearWheelSkelControl.BoneRotation.Yaw, -DesiredWheelTurn, FMin(6.f * DeltaTime, 0.99f));
		}

		PreviousYaw = Rotation.Yaw;
	}

	// Update the turret rotation
	if (TurretLookAtSkelControl != None)
	{
		UDKRTSAIController = UDKRTSAIController(Controller);
		if (UDKRTSAIController != None)
		{
			TurretLookAtSkelControl.SetTargetLocation(UDKRTSAIController.FocusSpot);
			TurretLookAtSkelControl.InterpolateTargetLocation(DeltaTime);
		}
	}
}

/**
 * Called from the pawn's controller when the pawn is updating its rotation
 *
 * @param		NewRotation			New rotation that the pawn should be facing
 * @param		DeltaTime			Time since the last update
 */
simulated function FaceRotation(Rotator NewRotation, float DeltaTime)
{
	local UDKRTSAIController UDKRTSAIController;

	// Determine if we need to rotate the vehicle, or if we can just rotate the turret
	UDKRTSAIController = UDKRTSAIController(Controller);
	if (UDKRTSAIController != None)
	{
		// If we have a target and we're within range, then we don't need to do anything
		if (UDKRTSAIController.IsInState('EngagingEnemy') && UDKRTSAIController.EnemyTargetInterface != None && UDKRTSWeapon.InRange(UDKRTSAIController.EnemyTargetInterface.GetActor(), Location))
		{
			return;
		}

		// Don't rotate the vehicle if the focus spot is within the collision cylinder
		if (!UDKRTSAIController.IsInState('MovingToPoint') && VSize(UDKRTSAIController.GetDestinationPosition() - Location) <= GetCollisionRadius())
		{
			return;
		}
	}

	Super.FaceRotation(NewRotation, DeltaTime);
}

/**
 * Returns true if the pawn needs to turn in order to fire at the target location
 *
 * @param		TargetLocation			Where in the world the pawn needs to fire at
 * @return								Returns true if the pawn needs to turn
 */
function bool NeedsToTurnForFiring(Vector TargetLocation)
{
	local Vector SocketLocation;
	local Rotator SocketRotation;
	local Vector LookDir, AimDir;

	// If the turret properties are not valid, then use the NeedsToTurnWithPrecision function
	if (TurretSocketName == '' || TurretSocketName == 'None' || Mesh == None || Mesh.SkeletalMesh == None || Mesh.GetSocketByName(TurretSocketName) == None)
	{
		return NeedsToTurnWithPrecision(TargetLocation, (UDKRTSWeapon != None) ? UDKRTSWeapon.AimPrecision : 0.95f);
	}
	else
	{
		// Check against the turret socket
		Mesh.GetSocketWorldLocationAndRotation(TurretSocketName, SocketLocation, SocketRotation);

		LookDir = Vector(SocketRotation);
		LookDir.Z = 0.f;
		LookDir = Normal(LookDir);

		AimDir = TargetLocation - Location;
		AimDir.Z = 0.f;
		AimDir = Normal(AimDir);

		return ((LookDir Dot AimDir) < (UDKRTSWeapon != None) ? UDKRTSWeapon.AimPrecision : 0.95f);
	}
}

/**
 * Called when the pawn has died, and is to play back the dying animation
 *
 * @param		DamageType		Damage type that caused the pawn to die
 * @param		HitLoc			World hit location where the hit occured that caused the pawn to die
 */
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	// Play back the explosion sound
	if (ExplosionSoundCue != None)
	{
		PlaySound(ExplosionSoundCue);
	}

	// Spawn the explosion particle system if necessary
	if (EffectIsRelevant(Location, false) && ExplosionParticleTemplate != None && WorldInfo != None && WorldInfo.MyEmitterPool != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionParticleTemplate, Location);
	}

	Super.PlayDying(DamageType, HitLoc);
}

defaultproperties
{
	Begin Object Class=AudioComponent Name=MyAudioComponent
		bAutoPlay=false
		bStopWhenOwnerDestroyed=true
		bShouldRemainActiveIfDropped=true
	End Object
	EngineAmbientSound=MyAudioComponent
	Components.Add(MyAudioComponent)

	WheelRotationSpeed=196608.f
	MaxWheelTurn=5461.332f
}